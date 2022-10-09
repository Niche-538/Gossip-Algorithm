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
    L = while(s, Num, []),
    % io:fwrite("List of Actors: ~p~n", [L]),
    io:fwrite("Len of List: ~p~n", [tail_len(L)]),
    % M = while(s, 2, L),
    % io:fwrite("List of Actors: ~p~n", [M]),
    counter_attempt().

while(s, N, Li) ->
    while(N, Li).

while(0, L) ->
    reverse(L);
while(N, L) ->
    while(N - 1, [spawn(fun() -> actor_call() end) | L]).

actor_call() ->
    io:fwrite("").

tail_len(L) -> tail_len(L, 0).
tail_len([], Acc) -> Acc;
tail_len([_ | T], Acc) -> tail_len(T, Acc + 1).

counter_attempt() ->
    MCR = counters:new(1, [atomics]),
    counters:add(MCR, 1, 1),
    % X = counters:get(MCR, 1),
    counters:add(MCR, 1, 1),
    V = counters:get(MCR, 1),
    % persistent_term:put(my_counter_ref, MCR),
    % counters:add(persistent_term:get(my_counter_ref), 1, 9),
    % V = counters:get(persistent_term:get(my_counter_ref), 1),
    io:fwrite("Counter Var: ~p~n", [V]).
