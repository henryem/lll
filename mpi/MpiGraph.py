import itertools

import SetUtils

# A distributed undirected graph.  Nodes are simply integer IDs.  Nodes are 
# distributed, and each node knows its neighbors, some of which may reside
# in other processes.
# 
# Methods are _local_ unless otherwise specified.  For example, self.nodes()
# returns a set of nodes that reside on the local processor, not the whole set
# of nodes.  Global methods are prefixed with "global" and return MpiChunks or
# MpiCollection where appropriate.
class Graph(object):
  def __init__(self, commV):
    self.commV = commV
  
  def comm(self):
    return self.commV
  
  def nodes(self):
    pass
  
  def edges(self):
    pass
  
  def neighbors(self, node):
    pass
  
  def neighborhood(self, nodes):
    #FIXME
    pass
  

# A graph composed of a list of nodes distributed across machines, plus the
# edges incident to the nodes on each machine.  Unlike other potential 
# implementations of Graph (in particular, LazySubGraph), these lists are
# materialized.
class ConcreteGraph(object):
  def __init__(self, comm, nodesV, edgesV, neighborsV):
    self.nodesV = nodesV
    self.edgesV = edgesV
    self.neighborsV = neighborsV
    super(ConcreteGraph, self).__init__(self, comm)
  