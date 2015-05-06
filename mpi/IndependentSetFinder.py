import MpiGraph
import Utils

# Returns a maximal independent set (in the form of an MpiSet) in
# @graph.
def maximalIndependentSet(rand, graph):
  pass

# Returns an independent set (in the form of an MpiSet) in @graph found 
# by one iteration of Luby's algorithm.
def lubyIndependentSet(rand, graph):
  marks = markNodesRandomly(graph, lambda : Utils.randLargeInt(rand))
  return findLocalMinima(graph, marks)

def markNodesRandomly(graph, distribution):
  graph.nodes().map(lambda node: (node, distribution())).toDict()

def findLocalMinima(graph, marks):
  return findLocalMaxima(graph, marks, lambda x, y: x < y)

def findLocalMaxima(graph, marks, comparatorFunc):
  # We do this in two rounds.  First, we pare down the nodes on a single
  # processor by removing nodes with larger neighbors residing on the same
  # processor.  Then the remaining nodes (and their weights) are all-gathered
  # and a similar algorithm is run again, with each processor checking its
  # nodes against their neighbors in the rest of the graph.
  potentialLocalMaxima = findLocalMaximaAmongNodes(graph, graph.nodes(), marks, comparatorFunc)
  potentialsWithMarks = MpiDict(graph.comm(), {node: marks[node] for node in potentialLocalMaxima})
  allPotentialsWithMarks = potentialsWithMarks.collectEverywhere()
  allPotentials = set(allPotentialsWithMarks.keys())
  #FIXME: Implement this.
  remainingGraph = inducedSubgraphPlusFringe(graph, potentialLocalMaxima, allPotentials)
  localMaxima = findLocalMaximaAmongNodes(remainingGraph, potentialLocalMaxima, comparatorFunc)
  return localMaxima

# Find elements of @potentialMaxima (a set of nodes) that are strict local 
# maxima according to @comparatorFunc.
# This subroutine is a little complicated, but it is useful in implementing
# findLocalMaxima() above.
def findLocalMaximaAmongNodes(graph, potentialMaxima, marks, comparatorFunc)
  def isLocalMaximum(node):
    mark = marks[node]
    neighbors = graph.localNeighbors(node)
    return all(itertools.imap(lambda neighbor: comparatorFunc(mark, marks[neighbor]), neighbors))
  
  return potentialMaxima.filter(isLocalMaximum)


# A method for finding independent sets in graphs, intended for use in a 
# Moser-Tardos algorithm.
class IndependentSetFinder(object):
  def __init__(self):
    pass
  
  # The number of iterations to use when running the Moser-Tardos algorithm
  # using this algorithm to find independent sets on each iteration.
  def calculateNumIterations(self, graph):
    pass
  
  # Returns a function from subgraphs of @graph to sets of nodes local to this
  # processor.  The nodes are guaranteed to be independent in the subgraph 
  # (even the nodes returned on different processors).  The whole set of nodes
  # (across processors) is not guaranteed to be a maximum-size or maximal-size
  # independent set, but different implementations may make different
  # guarantees about that.
  def buildFinderFunc(self, rand, graph):
    pass


class MoserTardosIndependentSetFinder(IndependentSetFinder):
  def __init__(self):
    super(MoserTardosIndependentSetFinder, self).__init__(self)

  def calculateNumIterations(self, graph):
    pass
  
  def buildFinderFunc(self, rand, graph):
    pass


class SimpleChungIndependentSetFinder(IndependentSetFinder):
  def __init__(self):
    super(SimpleChungIndependentSetFinder, self).__init__(self)

  def calculateNumIterations(self, graph):
    pass
  
  def buildFinderFunc(self, rand, graph):
    pass


class WeakMisFinder(IndependentSetFinder):
  def __init__(self):
    super(WeakMisFinder, self).__init__(self)

  def calculateNumIterations(self, graph):
    pass
  
  def buildFinderFunc(self, rand, graph):
    pass