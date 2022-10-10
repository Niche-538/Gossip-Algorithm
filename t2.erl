-module(t2).
-export([start/1]).
-import(lists, [append/2, reverse/1]).
-import(gossip, [gossip/2]).
-import(push_sum, [push_sum/2]).

tail_len(L) -> tail_len(L, 0).
tail_len([], Acc) -> Acc;
tail_len([_ | T], Acc) -> tail_len(T, Acc + 1).

generateActors(N, MID) ->
    generateActors(N, [], MID).

generateActors(0, L, _) ->
    reverse(L);
generateActors(N, L, MID) ->
    generateActors(
        N - 1, [spawn(fun() -> actor_process(MID, counters:new(1, [atomics])) end) | L], MID
    ).

start(NumNodes) ->
    T = erlang:timestamp(),
    io:format("Start Time: ~p~n", [T]),

    %create a masterActor
    MID = spawn(fun() -> master_process() end),

    %create actors List
    L = generateActors(NumNodes, MID),
    io:format("List of Actors: ~p ~n~n", [L]),
    %send List to Master
    MID ! {actorList, {L}}.

master_process() ->
    % C = counters:new(1, [atomics]),
    % counters:add(C, 1, 1),
    % persistent_term:put(cr, C),
    receive
        {actorList, {L}} ->
            Akda = rand:uniform(tail_len(L)),
            io:format("Chosen Actor ID: ~p~n~n", [lists:nth(Akda, L)]),
            lists:nth(Akda, L) ! {message, {firstMessage, "Gossip Message", L, Akda}},
            master_process();
        {AID, RAID, Message} ->
            % counters:add(persistent_term:get(cr), 1, 1),
            io:format("Actor ID: ~p  Recieved Id: ~p Message: ~p ~n", [AID, RAID, Message]),
            T = erlang:timestamp(),
            io:format("End Time: ~p~n", [T]),
            % CVal = counters:get(persistent_term:get(cr), 1),
            % TL = tail_len(L),
            % io:format("CVal: ~p Length:~p~n", [CVal, TL]),
            % case CVal == TL of
            %     true -> exit("Sent to all");
            %     false -> master_process()
            % end
            master_process()
    end.

actor_process(MID, MCR) ->
    receive
        {message, {firstMessage, Message, L, Akda}} ->
            counters:add(MCR, 1, 1),
            case counters:get(MCR, 1) == 1 of
                true ->
                    PID = self(),
                    % spawn(fun() -> full_network(Message, L, PID) end);
                    % spawn(fun() -> line_network(Message, L, PID, Akda) end);
                    spawn(fun() -> grid_2d(Message, L, PID, Akda) end);
                false ->
                    nothing
            end;
        {message, {Message, RAID, L, Akda}} ->
            counters:add(MCR, 1, 1),
            case counters:get(MCR, 1) == 1 of
                true ->
                    PID = self(),
                    % spawn(fun() -> full_network(Message, L, PID) end);
                    % spawn(fun() -> line_network(Message, L, PID, Akda) end);
                    spawn(fun() -> grid_2d(Message, L, PID, Akda) end);
                false ->
                    nothing
            end,
            case counters:get(MCR, 1) == 10 of
                true ->
                    MID ! {self(), RAID, Message};
                false ->
                    nothing
            end,
            actor_process(MID, MCR)
    end.

full_network(Message, L, RAID) ->
    lists:nth(rand:uniform(tail_len(L)), L) ! {message, {Message, RAID, L}},
    full_network(Message, L, RAID).

line_network(Message, L, RAID, Akda) ->
    LLen = tail_len(L),
    case Akda of
        1 ->
            lists:nth(2, L) ! {message, {Message, RAID, L, 2}};
        LLen ->
            Nid = LLen - 1,
            lists:nth(Nid, L) ! {message, {Message, RAID, L, Nid}};
        _ ->
            Neighbors_Index = [Akda - 1, Akda + 1],
            Chosen_Index = lists:nth(rand:uniform(2), Neighbors_Index),
            Chosen_Neighbor = lists:nth(Chosen_Index, L),
            Chosen_Neighbor ! {message, {Message, RAID, L, Chosen_Index}}
    end,
    line_network(Message, L, RAID, Akda).

grid_2d(Message, L, RAID, Akda) ->
    LenL = tail_len(L),
    Up = Akda - 4,
    Down = Akda + 4,
    Left = Akda - 1,
    Right = Akda + 1,

    case Akda rem 4 of
        0 ->
            Neighbor_IDs = [X || X <- [Up, Down, Left], X > 0, X < LenL + 1],
            Chosen_ID = lists:nth(rand:uniform(tail_len(Neighbor_IDs)), Neighbor_IDs),
            Chosen_Nebur = lists:nth(Chosen_ID, L),
            Chosen_Nebur ! {message, {Message, RAID, L, Chosen_ID}};
        1 ->
            Neighbor_IDs = [X || X <- [Up, Down, Right], X > 0, X < LenL + 1],
            Chosen_ID = lists:nth(rand:uniform(tail_len(Neighbor_IDs)), Neighbor_IDs),
            Chosen_Nebur = lists:nth(Chosen_ID, L),
            Chosen_Nebur ! {message, {Message, RAID, L, Chosen_ID}};
        _ ->
            Neighbor_IDs = [X || X <- [Up, Down, Left, Right], X > 0, X < LenL + 1],
            Chosen_ID = lists:nth(rand:uniform(tail_len(Neighbor_IDs)), Neighbor_IDs),
            Chosen_Nebur = lists:nth(Chosen_ID, L),
            Chosen_Nebur ! {message, {Message, RAID, L, Chosen_ID}}
    end,
    grid_2d(Message, L, RAID, Akda).
