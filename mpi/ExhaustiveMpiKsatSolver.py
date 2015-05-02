from MpiKsatSolver import MpiKsatSolver

def unpack(binaryAssignment, assignment):
  #FIXME
  #TODO: Could be done much faster with a Gray code or a direct conversion
  # from binary to BitVector.
  for variableIdx = 1:n
    assignment[variableIdx] = (binaryAssignment >> (variableIdx-1)) & 0x1
  end
  

class ExhaustiveKsatSolver(MpiKsatSolver):
  def __init__(self):
    super(ExhaustiveKsatSolver, self).__init__()
  
  def solve(self, problem):
    n = problem.numVariables
    numPotentialSolutions = 2^n
    locallySatisfyingAssignments = []
    assignment = MpiKsatAssignment.emptyKsatAssignment(n)
    for binaryAssignment in xrange(numPotentialSolutions):
      unpack(binaryAssignment, assignment)
      if assignment.satisfiesClauses(localElements(problem)):
        locallySatisfyingAssignments.append(binaryAssignment)
    #NOTE: Could pare down the list of local assignments by periodically
    # communicating, if that would help.
    #FIXME: Not sure if gatherv() works this way.
    allSatisfyingAssignments = problem.comm().gatherv(locallySatisfyingAssignments)
    if problem.comm().rank == 0:
      #TODO: Find solutions that worked on all machines.
    #FIXME: Return something.