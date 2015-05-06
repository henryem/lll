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

# An exhaustive solver that distributes clauses across machines and
# parallelizes the work of checking each assignment.
class ExhaustiveDistMpiKsatSolver(MpiKsatSolver):
  def __init__(self, communicationFrequency):
    self.communicationFrequency = communicationFrequency
    super(ExhaustiveDistMpiKsatSolver, self).__init__()
  
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

def multithreadedExhaustiveDistMpiKsatSolver():
  return ExhaustiveDistMpiKsatSolver(COMMUNICATION_FREQUENCY_FOR_MULTITHREADED)

def distributedExhaustiveDistMpiKsatSolver():
  return ExhaustiveDistMpiKsatSolver(COMMUNICATION_FREQUENCY_FOR_DISTRIBUTED)


# An exhaustive solver that broadcasts clauses and partitions the space of
# assignments across machines.  Does essentially no communication.
class ExhaustiveDistMpiKsatSolver(MpiKsatSolver):
  def __init__(self):
    super(ExhaustiveDistMpiKsatSolver, self).__init__()
  
  def solve(self, rand, problem):
    comm = problem.comm()
    n = problem.numVariables
    numPotentialSolutions = 2**n
    binaryAssignments = MpiCollection.makeRange(comm, numPotentialSolutions)
    currentAssignment = MpiKsatAssignment.emptyMpiKsatAssignment(problem.comm(), n)
    currentLocalAssignment = currentAssignment.localAssignment()
    allClauses = problem.distributedClauses().collectEverywhere()
    def checkBinaryAssignment(binaryAssignment):
      unpack(binaryAssignment, currentLocalAssignment, n)
      return currentLocalAssignment.satisfiesClauses(allClauses)
    satisfyingBinaryAssignments = binaryAssignments.filter(checkBinaryAssignment)
    
    #FIXME
    
    def buildSolution():
      if len(satisfyingAssignments) > 0:
        print "%d out of %d satisfying assignments." % (len(satisfyingAssignments), numPotentialSolutions)
        return KsatSolution.success(list(satisfyingAssignments)[0])
      else:
        return KsatSolution.failure()
    
    return onMaster(problem.comm(), buildSolution)