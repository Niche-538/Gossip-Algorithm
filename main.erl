-module(main).
-export([main_process/3, start/1]).
-import(lists, [append/2, reverse/1]).
-import(gossip, [gossip/2]).
-import(push_sum, [push_sum/2]).

main_process(NumNodes, Topology, Algorithm) ->
    if
        Algorithm == "Gossip" ->
            gossip(NumNodes, Topology);
        true ->
            push_sum(NumNodes, Topology)
    end.

start(Num) ->
    L = while(Num),
    io:fwrite("List of Actors: ~p~n", [L]),
    io:fwrite("Len of List: ~p~n", [tail_len(L)]).

while(N) ->
    while(N, []).

while(0, L) ->
    reverse(L);
while(N, L) ->
    while(N - 1, [spawn(fun() -> actor_call() end) | L]).

actor_call() ->
    io:fwrite("").

tail_len(L) -> tail_len(L, 0).
tail_len([], Acc) -> Acc;
tail_len([_ | T], Acc) -> tail_len(T, Acc + 1).
