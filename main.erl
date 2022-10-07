-module(main).
-export([main_process/3]).
-import(gossip, [gossip/2]).
-import(push_sum, [push_sum/2]).



main_process(NumNodes, Topology, Algorithm) ->

  if Algorithm == "Gossip" ->
    gossip(NumNodes,Topology);
  true ->
    push_sum(NumNodes,Topology)
    end.




