-module(push_sum).
-export([start_push_sum_Algorithm/2]).
-import(lists, [append/2, reverse/1]).

tail_len(L) -> tail_len(L, 0).
tail_len([], Acc) -> Acc;
tail_len([_ | T], Acc) -> tail_len(T, Acc + 1).

generateActors(N,MID) ->
  generateActors(N, [], MID).

generateActors(0, L, _) ->
  reverse(L);

generateActors(N, L, MID) ->
  generateActors(N - 1, [spawn(fun() -> actor_process(MID, counters:new(1, [atomics])) end) | L], MID).

start_push_sum_Algorithm(NumNodes, Topology) ->
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
      lists:nth(1, L) ! {message, {firstMessage, 50, L}},
      master_process();

    {AID,RAID, Message} ->
      io:format("Actor ID: ~p  Recieved Id: ~p Message: ~p ~n", [AID, RAID, Message]),
      T = erlang:timestamp(),
      io:format("End Time: ~p~n", [T]),
      master_process()
  end.


actor_process(MID, MCR) ->
  receive
    {message, {firstMessage, S, L}}->
      counters:add(MCR, 1, 1),
      case counters:get(MCR, 1) ==1 of
        true ->
          PID = self(),
          spawn(fun() -> start_push_sum(S, 1, L, PID) end);
        false -> nothing
      end;
    {message, {S, RAID, L}} ->
      counters:add(MCR, 1, 1),
      case counters:get(MCR, 1) ==1 of
        true ->
          PID = self(),
          spawn(fun() -> start_push_sum(S, 1, L, PID) end);
        false -> nothing
      end,
      case counters:get(MCR, 1) == 10 of
        true ->
          MID ! {self(), RAID, S};
        false -> nothing
      end,
      actor_process(MID, MCR)
  end.


start_push_sum(S, W, L, RAID)->
  lists:nth(rand:uniform(tail_len(L)), L) ! {message, {S, RAID, L}},
  start_push_sum(S, W, L, RAID).
