from copy import deepcopy

import MpiKsatAssignment

class KsatSolution(object):
  def __init__(self, isSuccessfulV, assignmentV=None):
    assert(isSuccessfulV or assignmentV is None)
    self.isSuccessfulV = isSuccessfulV
    self.assignmentV = deepcopy(assignmentV)
  
  def isSuccessful(self):
    return self.isSuccessfulV
  
  def assignment(self):
    return self.assignmentV
  
  def __repr__(self):
    return ("successful solution: %s" % str(self.assignmentV) if self.isSuccessfulV else "unsuccessful solution")

def success(assignment):
  return KsatSolution(True, assignment)

def failure():
  return KsatSolution(False, None)