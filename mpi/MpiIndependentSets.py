import random

import Utils

# Algorithms for finding independent sets in MpiGraphs.  The sets themselves
# are distributed data structures.
class MpiSet(object):
  def __init__(self, localSubset):
    self.localSubset = localSubset

class LocalSubset(object):
  def __init__(self, elements):
    self.elements = elements

def withRandomIntMarks(graph):
  return MarkedMpiGraph(graph, withValues(lambda node: random.randint(0, sys.maxsize, graph)))

def withRandomBoolMarks(graph, p):
  return MarkedMpiGraph(graph, withValues(lambda node: Utils.randBernoulli(p), graph))

# @param self: A MarkedMpiGraph.
def localMinima(self, lessThanFunc)
  localMinima = Set{Int64}()
  for v in nodes(this.graph)
    const mark = this.marks[v]
    foundSmallerNeighbor = false
    for u in neighbors(this.graph, v)
      #TODO: Probably slow; there is a library that uses the type system to
      # avoid function calls like this for common functions, but I do not 
      # remember its name.
      # 
      # Read this as "If myMark >= neighborMark, I am not a local minimum."
      if !lessThanFunc(mark, this.marks[u])
        foundSmallerNeighbor = true
        break
      end
    end
    if !foundSmallerNeighbor
      push!(localMinima, v)
    end
  end
  localMinima
end