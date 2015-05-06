import MpiGraph

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