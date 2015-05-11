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
    #TODO: Could cache this, if it is expensive.
    otherLiterals = set(other.literals)
    return any(ownLiteral in otherLiterals for ownLiteral in self.literals)

def randomSatClause(k, numVariables, rand):
  #TODO: Both of these might be inefficient.
  literals = rand.choice(numVariables, k, replace=False)
  signs = [Utils.randBernoulli(rand, .5) for i in xrange(numVariables)]
  return SatClause(literals, signs)


class BroadcastKsatProblem(object):
  def __init__(self, k, numVariables, clausesByIdx, localClauseIndices):
    self.k = k
    self.numVariables = numVariables
    self.clausesByIdx = clausesByIdx
    self.localClauseIndices = localClauseIndices
  
  def toDependencyGraph(self, comm):
    def findNeighborsIndices(nodeIdx, node):
      return set(neighborIdx for neighborIdx, neighbor in self.clausesByIdx.items() if nodeIdx != neighborIdx and node.sharesLiteral(neighbor))
    neighborsOfLocalNodes = {localNodeIdx: findNeighborsIndices(localNodeIdx, self.clausesByIdx[localNodeIdx]) for localNodeIdx in self.localClauseIndices}
    return MpiGraph.graphFromLocal(comm, self.localClauseIndices, neighborsOfLocalNodes)

# A distributed k-SAT problem.
class MpiKsatProblem(object):
  def __init__(self, k, numVariables, distributedClausesV):
    self.k = k
    self.numVariables = numVariables
    self.distributedClausesV = distributedClausesV
  
  def comm(self):
    return self.distributedClausesV.comm()
  
  def distributedClauses(self):
    return self.distributedClausesV
  
  def localClauses(self):
    return self.distributedClausesV.localDict().values()
    
  def localClausesByIdx(self):
    return self.distributedClausesV.localDict()
  
  def toBroadcast(self):
    allClausesByIdx = self.distributedClausesV.collectEverywhere()
    return BroadcastKsatProblem(self.k, self.numVariables, allClausesByIdx, self.distributedClausesV.localDict().keys())
  
  def __repr__(self):
    return "[%d] %s" % (
      self.comm().rank,
      "&".join("(%s)" % clause for clause in self.localClauses()))

class KsatGenerator(object):
  def __init__(self):
    pass
  
  def generate(self, comm, rand):
    raise NotImplementedError()

class RandomMpiKsatGenerator(KsatGenerator):
  def __init__(self, k, numVariables, numClauses):
    self.k = k
    self.numVariables = numVariables
    self.numClauses = numClauses
  
  def generate(self, comm, rand):
    # It is assumed that @rand is identical on each machine.
    startingSeed = Utils.randLargeInt(rand)
    clauses = (MpiCollection.makeRange(comm, self.numClauses)
      .map(lambda idx: (idx, randomSatClause(self.k, self.numVariables, MpiUtils.makeRandForItem(startingSeed, idx))))
      .toDict())
    return MpiKsatProblem(self.k, self.numVariables, clauses)