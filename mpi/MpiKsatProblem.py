import random
import itertools
import sys

import MpiCollection
import MpiUtils
import MpiGraph
import Utils
import CollectionUtils

class SatClause(object):
  def __init__(self, literals, signs):
    self.literals = literals
    self.signs = signs
  
  def __repr__(self):
    return "|".join(("%d" % l if s else "!%d" % l) for (l, s) in self.iterator())
  
  # An iterator over (literal, sign) pairs.
  def iterator(self):
    return itertools.izip(self.literals, self.signs)
  
  def sharesLiteral(self, other):
    otherLiterals = set(other.literals)
    return any(ownLiteral in otherLiterals for ownLiteral in self.literals)

def randomSatClause(k, numVariables, rand):
  #TODO: Both of these might be inefficient.
  literals = rand.choice(numVariables, k, replace=False)
  signs = [Utils.randBernoulli(rand, .5) for i in xrange(numVariables)]
  return SatClause(literals, signs)


# A distributed k-SAT problem.
class MpiKsatProblem(object):
  def __init__(self, k, numVariables, distributedClausesV):
    self.k = k
    self.numVariables = numVariables
    self.distributedClausesV = distributedClausesV
  
  def toDependencyGraph(self):
    # We assume the number of nodes is small; in that case, the most
    # communication-efficient way to build the graph is to broadcast the nodes 
    # and compute edges everywhere.
    localNodes = self.localClausesByIdx()
    allNodesByIdx = self.distributedClauses().values().collectEverywhere()
    
    def findNeighborsIndices(node):
      set(neighborIdx for neighborIdx, neighbor in enumerate(allNodesByIdx) if node.sharesLiteral(neighbor))
    
    #TODO: Could be more efficient ways to do this.  For example, we could find 
    # edges by shared variable rather than by examining all pairs of nodes.
    neighborsOfLocalNodes = {localNodeIdx: findNeighborsIndices(localNode) for localNodeIdx, localNode in localNodes}
    #TODO: Do we need the reverse edges too?  This won't include edges
    # like (nonLocalNeighborIdx, localNodeIdx).  For now it seems we don't
    # need the edges at all, only the neighbor sets.
    #localEdges = CollectionUtils.union(set((localNodeIdx, neighborIdx) for neighborIdx in neighborIndices) for localNodeIdx, neighborIndices in neighborsOfLocalNodes)
    return MpiGraph.graphFromLocal(set(localNodes.keys()), neighborsOfLocalNodes)
  
  def comm(self):
    return self.distributedClausesV.comm()
  
  def distributedClauses(self):
    return self.distributedClausesV
  
  def localClauses(self):
    return self.distributedClausesV.localDict().values()
    
  def localClausesByIdx(self):
    return self.distributedClausesV.localDict()
  
  def __repr__(self):
    return "[%d] %s" % (
      self.comm().rank,
      "&".join("(%s)" % clause for clause in self.localClauses()))

class KsatGenerator(object):
  def __init__(self):
    pass
  
  def generate(self, comm, rand):
    pass

class RandomMpiKsatGenerator(KsatGenerator):
  def __init__(self, k, numVariables, numClauses):
    self.k = k
    self.numVariables = numVariables
    self.numClauses = numClauses
  
  def generate(self, comm, rand):
    # It is assumed that @rand is identical on each machine.  To avoid actually
    # generating the same set of clauses on each machine, we make the seed a
    # deterministic function of the machine ID.
    newRand = MpiUtils.reseed(comm, rand)
    clauses = (MpiCollection.makeRange(comm, self.numClauses)
      .map(lambda idx: (idx, randomSatClause(self.k, self.numVariables, newRand)))
      .toDict())
    return MpiKsatProblem(self.k, self.numVariables, clauses)