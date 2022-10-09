-module(trying).
-import(lists, [append/2, reverse/1]).
-export([start/1]).

start(Num) ->
    L = while(Num),
    io:fwrite("L ala ka?: ~p~n", [L]),
    io:fwrite("L chi len: ~p~n", [tail_len(L)]).

while(N) ->
    while(0, N, []).

while(N, N, L) ->
    reverse(L);
while(S, N, L) ->
    while(S + 1, N, [spawn(fun() -> actor_call() end) | L]).

actor_call() ->
    io:fwrite("").

tail_len(L) -> tail_len(L, 0).
tail_len([], Acc) -> Acc;
tail_len([_ | T], Acc) -> tail_len(T, Acc + 1).
