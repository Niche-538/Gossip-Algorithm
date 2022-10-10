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
    T = erlang:timestamp(),
    io:format("Start Time: ~p~n", [T]),

    %create a masterActor
    MID = spawn(fun() -> master_process() end),

    %create actors List
    L = generateActors(NumNodes, MID),

    %send List to Master
    MID ! {actorList, {L}}.


master_process()->
    receive
        {actorList, {L}} ->
            lists:nth(1, L) ! {message, {firstMessage, "Gossip Message", L}},
            master_process();

        {AID,RAID, Message} ->
            io:format("Actor ID: ~p  Recieved Id: ~p Message: ~p ~n", [AID, RAID, Message]),
            T = erlang:timestamp(),
            io:format("End Time: ~p~n", [T]),
            master_process()
    end.


actor_process(MID, MCR) ->
    receive
        {message, {firstMessage, Message, L}}->
            counters:add(MCR, 1, 1),
            case counters:get(MCR, 1) ==1 of
                true ->
                    PID = self(),
                    spawn(fun() -> start_gossip(Message, L, PID) end);
                false -> nothing
            end;
        {message, {Message, RAID, L}} ->
            counters:add(MCR, 1, 1),
            case counters:get(MCR, 1) ==1 of
                true ->
                    PID = self(),
                    spawn(fun() -> start_gossip(Message, L, PID) end);
                false -> nothing
            end,
            case counters:get(MCR, 1) == 10 of
                true ->
                    MID ! {self(), RAID, Message};
                false -> nothing
            end,
        actor_process(MID, MCR)
    end.


start_gossip(Message, L, RAID)->

    lists:nth(rand:uniform(tail_len(L)), L) ! {message, {Message, RAID, L}},
    start_gossip(Message, L, RAID).
