-module(gossip).
-export([start_gossip_Algorithm/2]).
-import(lists, [append/2, reverse/1]).

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

start_gossip_Algorithm(NumNodes, Topology) ->
    T = erlang:timestamp(),
    io:format("Start Gossip Time: ~p~n", [T]),

    io:format("Topology: ~p~n", [Topology]),
    %create a masterActor
    MID = spawn(fun() -> master_process(Topology) end),

    %create actors List
    L = generateActors(NumNodes, MID),

    %send List to Master
    MID ! {actorList, {L}}.

master_process(Topology) ->
    receive
        {actorList, {L}} ->
            Index = rand:uniform(tail_len(L)),
            io:format("Chosen Actor ID: ~p~n~n", [lists:nth(Index, L)]),
            lists:nth(Index, L) ! {message, {firstMessage, "Gossip Message", L, Index, Topology}},
            master_process(Topology);
        {AID, RAID, Message} ->
            io:format("Actor ID: ~p  Recieved Id: ~p Message: ~p ~n", [AID, RAID, Message]),
            T = erlang:timestamp(),
            io:format("End Time: ~p~n", [T]),
            master_process(Topology)
    end.

actor_process(MID, MCR) ->
    receive
        {message, {firstMessage, Message, L, Index, Topology}} ->
            counters:add(MCR, 1, 1),
            case counters:get(MCR, 1) == 1 of
                true ->
                    PID = self(),
                    case Topology of
                        "Full" ->
                            spawn(fun() -> full_network(Message, L, PID, Index, Topology) end);
                        "Line" ->
                            spawn(fun() -> line_network(Message, L, PID, Index, Topology) end);
                        "2D" ->
                            spawn(fun() -> grid_2d(Message, L, PID, Index, Topology) end);
                        "imperfect 3D" ->
                            spawn(fun() -> grid_2d(Message, L, PID, Index, Topology) end)
                    end;
                false ->
                    nothing
            end;
        {message, {Message, RAID, L, Index, Topology}} ->
            counters:add(MCR, 1, 1),
            case counters:get(MCR, 1) == 1 of
                true ->
                    PID = self(),
                    case Topology of
                        "Full" ->
                            spawn(fun() -> full_network(Message, L, PID, Index, Topology) end);
                        "Line" ->
                            spawn(fun() -> line_network(Message, L, PID, Index, Topology) end);
                        "2D" ->
                            spawn(fun() -> grid_2d(Message, L, PID, Index, Topology) end);
                        "imperfect 3D" ->
                            spawn(fun() -> imperfect_3d(Message, L, PID, Index, Topology) end)
                    end;
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

full_network(Message, L, RAID, Index, Topology) ->
    Chosen_IDT = rand:uniform(tail_len(L)),
    Chosen_Actor = lists:nth(Chosen_IDT, L),
    Chosen_Actor ! {message, {Message, RAID, L, Index, Topology}},
    full_network(Message, L, RAID, Index, Topology).

line_network(Message, L, RAID, Index, Topology) ->
    LLen = tail_len(L),
    case Index of
        1 ->
            lists:nth(2, L) ! {message, {Message, RAID, L, 2, Topology}};
        LLen ->
            Nid = LLen - 1,
            lists:nth(Nid, L) ! {message, {Message, RAID, L, Nid, Topology}};
        _ ->
            Neighbors_Index = [Index - 1, Index + 1],
            Chosen_Index = lists:nth(rand:uniform(2), Neighbors_Index),
            Chosen_Neighbor = lists:nth(Chosen_Index, L),
            Chosen_Neighbor ! {message, {Message, RAID, L, Chosen_Index, Topology}}
    end,
    line_network(Message, L, RAID, Index, Topology).

grid_2d(Message, L, RAID, Index, Topology) ->
    LenL = tail_len(L),
    Up = Index - 4,
    Down = Index + 4,
    Left = Index - 1,
    Right = Index + 1,
    case Index rem 4 of
        0 ->
            Neighbor_IDs = [X || X <- [Up, Down, Left], X > 0, X < LenL + 1],
            grids_xtra(L, Neighbor_IDs, Message, RAID, Topology);
        1 ->
            Neighbor_IDs = [X || X <- [Up, Down, Right], X > 0, X < LenL + 1],
            grids_xtra(L, Neighbor_IDs, Message, RAID, Topology);
        _ ->
            Neighbor_IDs = [X || X <- [Up, Down, Left, Right], X > 0, X < LenL + 1],
            grids_xtra(L, Neighbor_IDs, Message, RAID, Topology)
    end,
    grid_2d(Message, L, RAID, Index, Topology).

grids_xtra(L, NL, Message, RAID, Topology) ->
    Chosen_ID = lists:nth(rand:uniform(tail_len(NL)), NL),
    Chosen_Nebur = lists:nth(Chosen_ID, L),
    Chosen_Nebur ! {message, {Message, RAID, L, Chosen_ID, Topology}}.

imperfect_3d(Message, L, RAID, Index, Topology) ->
    LenL = tail_len(L),
    Up = Index - 4,
    Down = Index + 4,
    Left = Index - 1,
    Right = Index + 1,
    D_UL = Index - 5,
    D_UR = Index - 3,
    D_DL = Index + 3,
    D_DR = Index + 5,
    case Index rem 4 of
        0 ->
            Neighbor_IDs1 = [
                X
             || X <- [Up, Down, Left, D_UL, D_DL], X > 0, X < LenL + 1
            ],
            Extra_N1 = [
                Y
             || Y <- lists:seq(1, tail_len(L)), lists:member(Y, Neighbor_IDs1) == false
            ],
            RN1 = rand:uniform(tail_len(Extra_N1)),
            Extra_Neighbor1 = [lists:nth(RN1, Extra_N1)],
            NewNeighborList1 = Neighbor_IDs1 ++ Extra_Neighbor1,
            grids_xtra(L, NewNeighborList1, Message, RAID, Topology);
        1 ->
            Neighbor_IDs2 = [
                X
             || X <- [Up, Down, Right, D_UR, D_DR], X > 0, X < LenL + 1
            ],
            Extra_N2 = [
                Y
             || Y <- lists:seq(1, tail_len(L)), lists:member(Y, Neighbor_IDs2) == false
            ],
            RN2 = rand:uniform(tail_len(Extra_N2)),
            Extra_Neighbor2 = [lists:nth(RN2, Extra_N2)],
            NewNeighborList2 = Neighbor_IDs2 ++ Extra_Neighbor2,
            grids_xtra(L, NewNeighborList2, Message, RAID, Topology);
        _ ->
            Neighbor_IDs3 = [
                X
             || X <- [Up, Down, Left, Right, D_UL, D_UR, D_DL, D_DR], X > 0, X < LenL + 1
            ],
            Extra_N3 = [
                Y
             || Y <- lists:seq(1, tail_len(L)), lists:member(Y, Neighbor_IDs3) == false
            ],
            RN3 = rand:uniform(tail_len(Extra_N3)),
            Extra_Neighbor3 = [lists:nth(RN3, Extra_N3)],
            NewNeighborList3 = Neighbor_IDs3 ++ Extra_Neighbor3,
            grids_xtra(L, NewNeighborList3, Message, RAID, Topology)
    end,
    imperfect_3d(Message, L, RAID, Index, Topology).
