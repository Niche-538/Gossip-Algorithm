-module(trying).
-export([start/1]).
-import(lists, [append/2, reverse/1]).
-import(gossip, [gossip/2]).
-import(push_sum, [push_sum/2]).

tail_len(L) -> tail_len(L, 0).
tail_len([], Acc) -> Acc;
tail_len([_ | T], Acc) -> tail_len(T, Acc + 1).

generateActors(N,MID) ->
    generateActors(N, [], MID).

generateActors(0, L, _) ->
    reverse(L);

generateActors(N, L, MID) ->
    generateActors(N - 1, [spawn(fun() -> actor_process(MID, counters:new(1, [atomics])) end) | L], MID).

start(NumNodes) ->
    %create a masterActor
    MID = spawn(fun() -> master_process() end),

    %create actors List
    L = generateActors(NumNodes, MID),

    %send List to Master
    MID ! {actorList, {L}},

    io:fwrite("Len of List: ~p~n", [tail_len(L)]).


master_process()->
    receive
        {actorList, {L}} ->
            lists:nth(1, L) ! {message, {"Gossip Message", L}};

        {AID, {pratik}} ->
            io:format("Actor ID: ~p ~n", [AID]),
            master_process()
    end.

actor_process(MID, MCR) ->
    receive
        {message, {Message, L}} ->
            counters:add(MCR, 1, 1),
            V = counters:get(MCR, 1),
            io:format("Counter: ~p ~n",[V]),
            case V of
                1 -> spawn(fun() -> start_gossip(Message, L) end);
                2->  io:format("2");
                10 -> io:format("Actor ID: ~p ~n",[self()])
            end,
            actor_process(MID, MCR)
    end.

start_gossip(Message, L)->
    lists:nth(rand:uniform(tail_len(L)), L) ! {message, {Message, L}},
    start_gossip(Message, L).