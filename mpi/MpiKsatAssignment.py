import numpy as np
import itertools

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
  
  def pack(self):
    return sum(2**i if value else 0 for i, value in enumerate(self.values))

  def __repr__(self):
    return "".join((str(value) for value in self.values))

def unpack(binaryAssignment, n):
  assignment = emptyKsatAssignment(n)
  unpackTo(binaryAssignment, assignment, n)
  return assignment

def unpackTo(binaryAssignment, assignment, n):
  for variableIdx in xrange(n):
    assignment.values[variableIdx] = (binaryAssignment >> variableIdx) & 0x1


def uniformRandomKsatAssignment(rand, numVariables):
  #TODO: Inefficient for storing booleans.
  return KsatAssignment(rand.randint(0, 2, size=numVariables))

def emptyKsatAssignment(numVariables):
  #TODO: Inefficient for storing booleans.
  return KsatAssignment(np.zeros(numVariables, dtype=np.int))

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