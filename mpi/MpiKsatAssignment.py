import numpy as np

# An assignment to all variables of a KsatProblem.
class KsatAssignment(object):
  def __init__(self, assignment):
    self.assignment = assignment
  
  def satisfiesProblem(self, clauses):
    return all(self.satisfiesClause(clause) for clause in clauses)
  
  def satisfiesClause(self, clause):
    return any(self.assignment[l] == s for l, s in clause.iterator())

def uniformRandomKsatAssignment(numVariables):
  #TODO: Inefficient for storing booleans.
  return KsatAssignment(np.random.randint(2, size=numVariables, dtype='bool_'))

def emptyKsatAssignment(numVariables):
  #TODO: Inefficient for storing booleans.
  return KsatAssignment(np.zeros(numVariables, dtype='bool_'))

class MpiKsatAssignment(object):
  def __init__(self, assignmentChunks):
    self.assignmentChunks = assignmentChunks