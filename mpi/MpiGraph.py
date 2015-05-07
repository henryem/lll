import itertools

import SetUtils

# A distributed undirected graph.  Nodes are simply integer IDs.  Nodes are 
# distributed, and each node knows its neighbors, some of which may reside
# in other processes.
# 
# Methods return distributed collections unless otherwise specified.  Methods
# prefixed with "local" return ordinary collections.
class Graph(object):
  def __init__(self):
    pass
  
  def nodesIterator(self):
    pass
  
  def nodesSet(self):
    pass
  
  def localNeighbors(self, node):
    pass
  
  def inducedSubgraphPlusFringe(self, nodes, fringe):
    return LazyFringedSubgraph(self, nodes, fringe)
  
  def inducedSubgraph(self, nodes):
    return LazySubgraph(self, nodes)
  

# A graph composed of a list of nodes distributed across machines, plus the
# edges incident to the nodes on each machine.  Unlike other potential 
# implementations of Graph (in particular, LazySubgraph), these lists are
# materialized.
class ConcreteGraph(Graph):
  def __init__(self, nodesV, neighborsV):
    self.nodesV = nodesV
    self.neighborsV = neighborsV
    super(ConcreteGraph, self).__init__()

  def comm(self):
    return self.nodesV.comm()
  
  def nodesIterator(self):
    return self.nodesV
  
  def nodesSet(self):
    return self.nodesV
  
  def localNeighbors(self, node):
    #TODO: May be slow.  Should be O(#neighbors).
    return self.neighborsV[node] & self.nodesSet()

def graphFromLocal(comm, nodes, neighbors):
  return ConcreteGraph(MpiCollection.setFromLocal(comm, nodes), MpiCollection.dictFromLocal(comm, neighbors))

class LazyFringedSubgraph(Graph):
  def __init__(self, supergraph, nodeSubset, fringe):
    self.supergraph = supergraph
    #FIXME: May need to reify this.
    self.nodeSubset = nodeSubset
    self.fringe = fringe
    super(LazyFringedSubgraph, self).__init__()
  
  def comm(self):
    return self.supergraph.comm()
  
  def nodesIterator(self):
    return collectionFromLocal(self.comm(), itertools.chain(self.nodeSubset.localSet(), self.fringe.localSet()))

  def nodesSet(self):
    #FIXME: Very inefficient to do this many times.
    return collectionFromLocal(self.comm(), self.nodeSubset.localSet() | self.fringe.localSet())
  
  def localNeighbors(self, node):
    return self.supergraph.localNeighbors(node) & self.nodesSet()

class LazySubgraph(Graph):
  def __init__(self, supergraph, nodeSubset):
    self.supergraph = supergraph
    #FIXME: May need to reify this.
    self.nodeSubset = nodeSubset
    super(LazySubgraph, self).__init__()
  
  def comm(self):
    return self.supergraph.comm()
  
  def nodesIterator(self):
    return self.nodeSubset

  def nodesSet(self):
    return self.nodeSubset
  
  def localNeighbors(self, node):
    return self.supergraph.localNeighbors(node) & self.nodesSet()