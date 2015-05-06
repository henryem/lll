import random
import itertools
import sys

import MpiCollection
import MpiUtils
import Utils

class SatClause(object):
  def __init__(self, literals, signs):
    self.literals = literals
    self.signs = signs
  
  def __repr__(self):
    return "|".join(("%d" % l if s else "!%d" % l) for (l, s) in self.iterator())
  
  # An iterator over (literal, sign) pairs.
  def iterator(self):
    return itertools.izip(self.literals, self.signs)

def randomSatClause(k, numVariables, rand):
  #TODO: Both of these might be inefficient.
  literals = rand.choice(numVariables, k, replace=False)
  signs = [Utils.randBernoulli(rand, .5) for i in xrange(numVariables)]
  return SatClause(literals, signs)

# A distributed k-SAT problem.
class MpiKsatProblem(object):
  def __init__(self, k, numVariables, distributedClauses):
    self.k = k
    self.numVariables = numVariables
    self.distributedClauses = distributedClauses
  
  # def toDependencyGraph(self):
  #   localNodes = self.distributedClauses.
  #FIXME
  
  def comm(self):
    return self.distributedClauses.comm()
  
  def localClauses(self):
    return self.distributedClauses.localDict().values()
    
  def localClausesByIdx(self):
    return self.distributedClauses.localDict()
  
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
