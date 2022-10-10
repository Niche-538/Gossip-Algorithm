-module(push_sum).
-export([start/2]).
-import(lists, [append/2, reverse/1]).

tail_len(L) -> tail_len(L, 0).
tail_len([], Acc) -> Acc;
tail_len([_ | T], Acc) -> tail_len(T, Acc + 1).

generateActors(N,MID) ->
  generateActors(N, [], MID).

generateActors(0, L, _) ->
  reverse(L);

generateActors(N, L, MID) ->
  generateActors(N - 1, [spawn(fun() -> actor_process(MID, N, counters:new(1, [atomics]) , counters:new(1, [atomics]),counters:new(1, [atomics])) end) | L], MID).

start(NumNodes, Topology) ->
  T = erlang:timestamp(),
  io:format("Start Time: ~p~n", [T]),
  io:format("Topology: ~p~n", [Topology]),
  %create a masterActor
  MID = spawn(fun() -> master_process() end),

  %create actors List
  L = generateActors(NumNodes, MID),

  %send List to Master
  MID ! {actorList, {L}}.


master_process()->
  receive
    {actorList, {L}} ->
      Akda = rand:uniform(tail_len(L)),
      lists:nth(Akda, L) ! {message, {firstMessage, L, Akda}},
      master_process();

    {AID,RAID, S , W } ->
      io:format("Actor ID: ~p  Recieved Id: ~p S: ~p W: ~p ~n", [AID, RAID, S , W]),
      T = erlang:timestamp(),
      io:format("End Time: ~p~n", [T]),
      master_process()
  end.


actor_process(MID, N, S, W , Change) ->

  receive
    {message, {firstMessage, L, Akda}}->
      counters:add(S, 1, Akda),
      counters:add(W, 1, 1),
      PID = self(),
      CID = spawn(fun() -> start_push_sum(S, W, L, PID, Akda) end),
      CID ! {newSW, S, W};

    {message, {S_Received, W_Received, L , RAID, Akda }} ->
        Val = counters:get(W, 1),
        case Val of
          0 ->
              counters:add(W, 1, 1),
              counters:add(S, 1, Akda),
              PID = self(),
              case abs((counter:get(S_Received, 1)/counter:get(W_Received, 1)) - (counter:get(S, 1)/counter:get(W, 1))) < 0.0000000001 of
                true ->
                  counters:add(Change, 1, 1);
                false ->
                  counter:add(Change, 1, -1 * counter:get(Change, 1))
              end,

              counters:add(S, 1, ((counter:get(S_Received, 1)-(counter:get(S, 1)))/2)),
              counters:add(W, 1, ((counter:get(W_Received, 1)-(counter:get(W, 1)))/2)),
              CID = spawn(fun() -> start_push_sum(S, W, L, PID, Akda) end),
              persistent_term:put("child", CID),
              persistent_term:get("child") ! {newSW, S, W};

          _->
            case (counter:get(S_Received, 1)/counter:get(W_Received, 1)) - (counter:get(S, 1)/counter:get(W, 1)) < 0.0000000001 of
              true ->
                counters:add(Change, 1, 1);
              false ->
                counter:add(Change, 1, -1 * counter:get(Change, 1))
            end,
            counters:add(S, 1, ((counter:get(S_Received, 1)-(counter:get(S, 1)))/2)),
            counters:add(W, 1, ((counter:get(W_Received, 1)-(counter:get(W, 1)))/2)),
            persistent_term:get("child") ! {newSW, S, W}

        end,

        case counters:get(Change, 1) == 3 of
          true ->
              MID ! {self(), RAID, S , W };
          false ->
            nothing
        end,
        actor_process(MID, N, S, W, Akda)
  end.


start_push_sum(S, W, L, RAID, Akda)->
  receive
     {newSW, SNew, WNew} ->
       lists:nth(rand:uniform(tail_len(L)), L) ! {message, {SNew, WNew, L, RAID, Akda}},
        start_push_sum(SNew, WNew, L, RAID, Akda)
  end,
  lists:nth(rand:uniform(tail_len(L)), L) ! {message, {S, W, L, RAID, Akda}},
  start_push_sum(S, W, L, RAID, Akda).


