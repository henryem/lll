from MpiKsatSolver import MpiKsatSolver
from MpiChunks import MpiChunks
from MpiUtils import onMaster
import MpiKsatAssignment
import KsatSolution

def unpack(binaryAssignment, assignment, n):
  for variableIdx in xrange(n):
    assignment.values[variableIdx] = (binaryAssignment >> variableIdx) & 0x1

def collectAndCombineLocalAssignments(comm, locallySatisfyingAssignments):
  allLocalAssignments = locallySatisfyingAssignments.collect()
  def findGloballySatisfyingAssignments():
    satisfyingAssignments = set(allLocalAssignments[0])
    for procAssignments in allLocalAssignments:
      satisfyingAssignments &= frozenset(procAssignments)
    return satisfyingAssignments
    
  return onMaster(comm, findGloballySatisfyingAssignments)

class ExhaustiveMpiKsatSolver(MpiKsatSolver):
  def __init__(self, communicationFrequency):
    self.communicationFrequency = communicationFrequency
    super(ExhaustiveMpiKsatSolver, self).__init__()
  
  def solve(self, rand, problem):
    n = problem.numVariables
    numPotentialSolutions = 2**n
    locallySatisfyingAssignments = MpiChunks(problem.comm(), [])
    assignment = MpiKsatAssignment.emptyMpiKsatAssignment(problem.comm(), n)
    assignmentsSinceLastCommunication = 0
    satisfyingAssignments = None
    if problem.comm().rank == 0:
      satisfyingAssignments = set()
    for binaryAssignment in xrange(numPotentialSolutions):
      unpack(binaryAssignment, assignment.localAssignment(), n)
      if assignment.localAssignment().satisfiesClauses(problem.localClauses()):
        locallySatisfyingAssignments.localData().append(binaryAssignment)
      assignmentsSinceLastCommunication += 1
      if assignmentsSinceLastCommunication >= self.communicationFrequency or binaryAssignment == numPotentialSolutions:
        newSatisfyingAssignments = collectAndCombineLocalAssignments(problem.comm(), locallySatisfyingAssignments)
        if problem.comm().rank == 0:
          satisfyingAssignments |= newSatisfyingAssignments
        locallySatisfyingAssignments = MpiChunks(problem.comm(), [])
        assignmentsSinceLastCommunication = 0
    
    def buildSolution():
      if len(satisfyingAssignments) > 0:
        print "%d out of %d satisfying assignments." % (len(satisfyingAssignments), numPotentialSolutions)
        return KsatSolution.success(list(satisfyingAssignments)[0])
      else:
        return KsatSolution.failure()
    
    return onMaster(problem.comm(), buildSolution)

COMMUNICATION_FREQUENCY_FOR_MULTITHREADED = 2**9
COMMUNICATION_FREQUENCY_FOR_DISTRIBUTED = 2**14

def multithreadedExhaustiveMpiKsatSolver():
  return ExhaustiveMpiKsatSolver(COMMUNICATION_FREQUENCY_FOR_MULTITHREADED)

def distributedExhaustiveMpiKsatSolver():
  return ExhaustiveMpiKsatSolver(COMMUNICATION_FREQUENCY_FOR_DISTRIBUTED)
