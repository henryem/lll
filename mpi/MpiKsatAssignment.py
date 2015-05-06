import numpy as np

import MpiChunks
import MpiBroadcast

# An assignment to all variables of a KsatProblem.
class KsatAssignment(object):
  def __init__(self, values):
    self.values = values
  
  def satisfiesClauses(self, clauses):
    return all(self.satisfiesClause(clause) for clause in clauses)
  
  def satisfiesClause(self, clause):
    return any(self.values[l] == s for l, s in clause.iterator())

def uniformRandomKsatAssignment(rand, numVariables):
  #TODO: Inefficient for storing booleans.
  return KsatAssignment(rand.randint(2, size=numVariables, dtype='bool_'))

def emptyKsatAssignment(numVariables):
  #TODO: Inefficient for storing booleans.
  return KsatAssignment(np.zeros(numVariables, dtype='bool_'))

class MpiKsatAssignment(object):
  def __init__(self, assignmentBroadcast):
    self.assignmentBroadcast = assignmentBroadcast

  def localAssignment(self):
    return self.assignmentBroadcast.value()

# One empty KsatAssignment per processor.
def emptyMpiKsatAssignment(comm, numVariables):
  return MpiKsatAssignment(MpiBroadcast.MpiMutableBroadcast(comm, emptyKsatAssignment(numVariables)))

# One uniform random KsatAssignment per processor, identical across processors
# if @rand is identical.
def uniformRandomMpiKsatAssignment(comm, rand, numVariables):
  return MpiKsatAssignment(MpiBroadcast.MpiMutableBroadcast(comm, uniformRandomKsatAssignment(rand, numVariables)))