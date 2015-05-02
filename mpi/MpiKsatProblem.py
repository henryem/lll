import random
import itertools

import MpiCollection
import Utils

class SatClause(object):
  def __init__(self, literals, signs):
    self.literals = literals
    self.signs = signs
  
  def __repr__(self):
    return "|".join(("%d" % l if s else "!%d" % l) for (l, s) in iterator(self))
  
  # An iterator over (literal, sign) pairs.
  def iterator(self):
    return itertools.izip(self.literals, self.signs)

def randomSatClause(k, numVariables):
  #TODO: Both of these might be inefficient.
  literals = random.sample(xrange(numVariables), k)
  signs = [Utils.randBernoulli(.5) for i in xrange(numVariables)]
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
    return self.distributedClauses.distributedClauses.comm
  
  def localClauses(self):
    return localElements(self.distributedClauses)
  
  def __repr__(self):
    return "[%d] %s" % (
      self.comm().rank,
      "&".join("(%s)" % clause for clause in self.distributedClauses.localElements()))

class KsatGenerator(object):
  def __init__(self):
    pass
  
  def generate(self, comm):
    pass

class RandomMpiKsatGenerator(KsatGenerator):
  def __init__(self, k, numVariables, numClauses):
    self.k = k
    self.numVariables = numVariables
    self.numClauses = numClauses
  
  def generate(self, comm):
    clauses = MpiCollection.makeRange(comm, self.numClauses).map(lambda idx: randomSatClause(self.k, self.numVariables))
    p = MpiKsatProblem(self.k, self.numVariables, clauses)
    #FIXME
    print p
    return p
