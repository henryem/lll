import itertools

import CollectionUtils
import SetUtils
import MpiCollection

# A distributed undirected graph.  Nodes are simply integer IDs.  Nodes are 
# distributed, and each node knows its neighbors, some of which may reside
# in other processes.
# 
# Methods return distributed collections unless otherwise specified.  Methods
# prefixed with "local" return ordinary collections.
class Graph(object):
  def __init__(self):
    pass
  
  def comm(self):
    raise NotImplementedError()
  
  def nodesIterator(self):
    raise NotImplementedError()
  
  def neighborsIterator(self, node):
    raise NotImplementedError()
  
  def filter(self, f):
    return LazySubgraph(self, f)
  
  def sizeEverywhere(self):
    return self.nodesIterator().sizeEverywhere()
  
  def maxDegreeEverywhere(self):
    return (self.nodesIterator()
      .map(lambda node: CollectionUtils.iterlen(self.neighborsIterator(node)))
      .reduceEverywhere(0, max))
  

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
    return self.nodesV.toCollection()

  def neighborsIterator(self, node):
    return self.neighborsV[node]

def graphFromLocal(comm, nodes, neighbors):
  return ConcreteGraph(MpiCollection.setFromLocal(comm, nodes), MpiCollection.dictFromLocal(comm, neighbors))


# The subgraph induced by a subset of nodes determined by a filter function.  
# That is, this graph includes nodes that pass @f and edges between those nodes 
# that were originally present in supergraph.
class LazySubgraph(Graph):
  def __init__(self, supergraph, f):
    self.supergraph = supergraph
    self.f = f
    super(LazySubgraph, self).__init__()
  
  def comm(self):
    return self.supergraph.comm()
  
  def nodesIterator(self):
    return self.supergraph.nodesIterator().filter(self.f)
  
  def neighborsIterator(self, node):
    return (neighbor for neighbor in self.supergraph.neighborsIterator(node) if self.f(neighbor))
  
  def filter(self, furtherFilterFunc):
    # Perhaps a more efficient implementation than the default.
    return LazySubgraph(self, lambda node: self.f(node) and furtherFilterFunc(node))