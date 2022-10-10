-module(main).
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
    %create a masterActor
    MID = spawn(fun() -> master_process() end),

    %create actors List
    L = generateActors(NumNodes, MID),

    %send List to Master
    MID ! {actorList, {L}}.

master_process() ->
    receive
        {actorList, {L}} ->
            Akda = rand:uniform(tail_len(L)),
            % Akda = 1,
            lists:nth(Akda, L) !
                {message, {firstMessage, "Gossip Message", L, Akda}},
            master_process();
        {AID, RAID, Message} ->
            io:format("Actor ID: ~p  Recieved Id: ~p Message: ~p ~n", [AID, RAID, Message]),
            master_process()
    end.

actor_process(MID, MCR) ->
    receive
        {message, {firstMessage, Message, L, Akda}} ->
            counters:add(MCR, 1, 1),
            case counters:get(MCR, 1) == 1 of
                true ->
                    PID = self(),
                    % spawn(fun() -> start_gossip(Message, L, PID) end);
                    spawn(fun() -> line_network(Message, L, PID, Akda) end);
                false ->
                    nothing
            end;
        {message, {Message, RAID, L, Akda}} ->
            counters:add(MCR, 1, 1),
            case counters:get(MCR, 1) == 1 of
                true ->
                    PID = self(),
                    % spawn(fun() -> start_gossip(Message, L, PID) end);
                    spawn(fun() -> line_network(Message, L, PID, Akda) end);
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

% start_gossip(Message, L, RAID) ->
%     lists:nth(rand:uniform(tail_len(L)), L) ! {message, {Message, RAID, L}},
%     start_gossip(Message, L, RAID).

line_network(Message, L, RAID, Akda) ->
    LLen = tail_len(L),
    % ID = rand:uniform(LLen),
    case Akda == 1 of
        true ->
            % Chosen_N = lists:nth(2, L),
            % io:format("Curr ID: ~p  Recieved Id: ~p Message: ~p ~n", [AID, RAID, Message]),
            % NewRAID =
            lists:nth(2, L) ! {message, {Message, RAID, L, 2}},
            line_network(Message, L, RAID, Akda);
        false ->
            nothing
    end,

    case Akda == LLen of
        true ->
            Nid = LLen - 1,
            lists:nth(Nid, L) ! {message, {Message, RAID, L, Nid}},
            line_network(Message, L, RAID, Akda);
        false ->
            nothing
    end,

    case (Akda > 1) and (Akda < LLen) of
        true ->
            Neighbors_Index = [Akda - 1, Akda + 1],
            Chosen_Index = lists:nth(rand:uniform(2), Neighbors_Index),
            Chosen_Neighbor = lists:nth(Chosen_Index, L),
            Chosen_Neighbor ! {message, {Message, RAID, L, Chosen_Index}},
            line_network(Message, L, RAID, Akda);
        false ->
            nothing
    end.
