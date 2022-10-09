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
    generateActors(N - 1, [spawn(fun() -> actor_process(MID) end) | L], MID).

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
            io:fwrite("List of Actors: ~p~n", [L]),
            lists:nth(1, L) ! {message, {"Gossip Message", L}};

        {AID, {Message, Counter}} ->
            io:format("Actor ID: ~p Output: ~p  ~p~n", [AID, Message, Counter]),
            master_process()
    end.

actor_process(MID) ->
    RecievedList = [],
    receive
        {message, {Message}, L} ->
            lists:nth(rand:uniform(tail_len(L)), L) ! {message, {Message, L}},
            addtoList,
            case tail_len(L) > 10 of
                true ->
                    MID ! {self(), {Message, tail_len(L)}};
                false ->
                   done
            end
    end.

