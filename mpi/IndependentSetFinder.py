import math
import itertools

import MpiGraph
import MpiCollection
import Utils

# Returns an independent set (in the form of an MpiSet) in @graph found 
# by one iteration of Luby's algorithm.
def lubyIndependentSet(rand, graph):
  marks = markNodesRandomly(graph, lambda : Utils.randLargeInt(rand))
  broadcastMarks = marks.collectEverywhere()
  return findLocalMinima(graph, broadcastMarks)

def markNodesRandomly(graph, distribution):
  return graph.nodesIterator().map(lambda node: (node, distribution())).toDict()

def findLocalMinima(graph, marks):
  return findLocalMaxima(graph, marks, lambda x, y: x < y)

def findLocalMaxima(graph, marks, comparatorFunc):
  def isLocalMaximum(node):
    mark = marks[node]
    return all((comparatorFunc(mark, marks[neighbor]) for neighbor in graph.neighborsIterator(node)))
  return graph.filter(isLocalMaximum).nodesIterator()


# A method for finding independent sets in graphs, intended for use in a 
# Moser-Tardos algorithm.
class IndependentSetFinder(object):
  def __init__(self):
    pass
  
  # The number of iterations to use when running the Moser-Tardos algorithm
  # using this algorithm to find independent sets on each iteration.
  def calculateNumIterations(self, problem, graph):
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
    super(MoserTardosIndependentSetFinder, self).__init__()

  def calculateNumIterations(self, problem, graph):
    pass
  
  def buildFinderFunc(self, rand, graph):
    pass


class SimpleChungIndependentSetFinder(IndependentSetFinder):
  def __init__(self):
    super(SimpleChungIndependentSetFinder, self).__init__()

  def calculateNumIterations(self, problem, graph):
    m = graph.sizeEverywhere()
    d = graph.maxDegreeEverywhere()
    p = 2.0**(-1.0*problem.k)
    base = 1.0/(math.e*p*(d+1))
    if base < 1.0:
      #TODO: Totally unclear if this is reasonable.
      return max(100, m)
    else:
      #TODO: Probably need a minimum threshold here, since the theoretical
      # analysis gives only asymptotic guarantees.  But it's not clear what
      # it should be.
      return max(100, int(math.ceil(math.log(base, m))))
  
  def buildFinderFunc(self, rand, graph):
    marks = markNodesRandomly(graph, lambda : Utils.randLargeInt(rand))
    broadcastMarks = marks.collectEverywhere()
    return lambda subgraph: findLocalMinima(subgraph, broadcastMarks)


class WeakMisFinder(IndependentSetFinder):
  def __init__(self):
    super(WeakMisFinder, self).__init__()

  def calculateNumIterations(self, graph):
    pass
  
  def buildFinderFunc(self, rand, graph):
    pass