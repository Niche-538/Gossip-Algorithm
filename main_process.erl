-module(main_process).
-export([start_main_process/3]).
-import(gossip, [start_gossip_Algorithm/2]).
-import(push_sum, [start_push_sum_Algorithm/2]).

start_main_process(NumNodes, Topology, Algorithm) ->
    case Algorithm of
        "Gossip" -> start_gossip_Algorithm(NumNodes, Topology);
        "Push Sum" -> start_push_sum_Algorithm(NumNodes, Topology)
    end.
