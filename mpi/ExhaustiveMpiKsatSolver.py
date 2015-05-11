import numpy as np

from MpiKsatSolver import MpiKsatSolver
from MpiChunks import MpiChunks
import MpiCollection
from MpiUtils import onMaster
import MpiUtils
import MpiKsatAssignment
import KsatSolution
import Utils

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
class ExhaustiveDataParallelSolver(MpiKsatSolver):
  def __init__(self, communicationFrequency):
    self.communicationFrequency = communicationFrequency
    super(ExhaustiveDataParallelSolver, self).__init__()
  
  def solve(self, rand, problem):
    comm = problem.comm()
    
    allClauses = problem.distributedClauses().values().collectEverywhere()
    
    if comm.rank == 0:
      print list(allClauses)
    
    n = problem.numVariables
    assert n < 63
    numPotentialSolutions = 2**n
    locallySatisfyingAssignments = MpiChunks(problem.comm(), [])
    assignment = MpiKsatAssignment.emptyMpiKsatAssignment(problem.comm(), n)
    localAssignment = assignment.localAssignment()
    assignmentsSinceLastCommunication = 0
    satisfyingAssignment = None
    numSatisfyingAssignments = 0
    if comm.rank == 0:
      satisfyingAssignments = set()
    for binaryAssignment in xrange(numPotentialSolutions):
      MpiKsatAssignment.unpackTo(binaryAssignment, localAssignment, n)
      if localAssignment.satisfiesClauses(problem.localClauses()):
        locallySatisfyingAssignments.localData().append(binaryAssignment)
      assignmentsSinceLastCommunication += 1
      if assignmentsSinceLastCommunication >= self.communicationFrequency or binaryAssignment == numPotentialSolutions-1:
        newSatisfyingAssignments = collectAndCombineLocalAssignments(comm, locallySatisfyingAssignments)
        if comm.rank == 0:
          numSatisfyingAssignments += len(newSatisfyingAssignments)
          if len(newSatisfyingAssignments) > 0 and satisfyingAssignment is None:
            satisfyingAssignment = MpiKsatAssignment.unpack(list(newSatisfyingAssignments)[0], n)
        locallySatisfyingAssignments = MpiChunks(comm, [])
        assignmentsSinceLastCommunication = 0
    
    def buildSolution():
      print "%d out of %d satisfying assignments." % (numSatisfyingAssignments, numPotentialSolutions)
      
      if satisfyingAssignment is not None:
        return KsatSolution.success(satisfyingAssignment)
      else:
        return KsatSolution.failure()
    
    return onMaster(comm, buildSolution)

COMMUNICATION_FREQUENCY_FOR_MULTITHREADED = 2**9
COMMUNICATION_FREQUENCY_FOR_DISTRIBUTED = 2**14

def multithreadedExhaustiveDataParallelSolver():
  return ExhaustiveDataParallelSolver(COMMUNICATION_FREQUENCY_FOR_MULTITHREADED)

def distributedExhaustiveDataParallelSolver():
  return ExhaustiveDataParallelSolver(COMMUNICATION_FREQUENCY_FOR_DISTRIBUTED)


# An exhaustive solver that broadcasts clauses and partitions the space of
# assignments across machines.  Does essentially no communication.
class ExhaustiveProcessParallelSolver(MpiKsatSolver):
  def __init__(self):
    super(ExhaustiveProcessParallelSolver, self).__init__()
  
  def solve(self, rand, problem):
    comm = problem.comm()
    n = problem.numVariables
    assert n < 63
    numPotentialSolutions = 2**n
    binaryAssignments = MpiCollection.makeRange(comm, numPotentialSolutions)
    currentAssignment = MpiKsatAssignment.emptyMpiKsatAssignment(problem.comm(), n)
    currentLocalAssignment = currentAssignment.localAssignment()
    #FIXME: collectEverywhere() probably should return a list, not an iterable.
    allClauses = list(problem.distributedClauses().values().collectEverywhere())
    
    if comm.rank == 0:
      print allClauses
    
    def checkBinaryAssignment(binaryAssignment):
      MpiKsatAssignment.unpackTo(binaryAssignment, currentLocalAssignment, n)
      return currentLocalAssignment.satisfiesClauses(allClauses)
    satisfyingBinaryAssignments = binaryAssignments.filter(checkBinaryAssignment)
    resultStatistics = (satisfyingBinaryAssignments
      .map(lambda elt: (1, elt))
      .reduce((0, -1), lambda countAndMaxA, countAndMaxB: (countAndMaxA[0] + countAndMaxB[0], max(countAndMaxA[1], countAndMaxB[1]))))
    
    def buildSolution():
      numSatisfyingAssignments, arbitrarySatisfyingAssignment = resultStatistics
      print "%d out of %d satisfying assignments." % (numSatisfyingAssignments, numPotentialSolutions)
      if arbitrarySatisfyingAssignment > -1:
        return KsatSolution.success(MpiKsatAssignment.unpack(arbitrarySatisfyingAssignment, n))
      else:
        return KsatSolution.failure()
    
    return onMaster(problem.comm(), buildSolution)

# A solver that broadcasts clauses and partitions a random subset of the
# set of assignments across machines.  Does essentially no communication.  Not
# guaranteed to find a solution if one exists.
#TODO: Refactor to share code with the exhaustive version.
class SamplingProcessParallelSolver(MpiKsatSolver):
  def __init__(self, numSamples):
    self.numSamples = numSamples
    super(SamplingProcessParallelSolver, self).__init__()
  
  def solve(self, rand, problem):
    comm = problem.comm()
    n = problem.numVariables
    numSamples = self.numSamples
    processorRand = MpiUtils.reseed(comm, rand)
    startingSeed = Utils.randLargeInt(rand)
    allClauses = list(problem.distributedClauses().values().collectEverywhere())
    satisfyingAssignments = (MpiCollection.makeRange(comm, numSamples)
      .map(lambda idx: MpiKsatAssignment.uniformRandomKsatAssignment(processorRand, n))
      .filter(lambda assignment: assignment.satisfiesClauses(allClauses)))
    
    #if comm.rank == 0:
      #print allClauses
    
    def reduceResultStatistics(countAndArbitraryElementA, countAndArbitraryElementB):
      newCount = countAndArbitraryElementA[0] + countAndArbitraryElementB[0]
      newArbitraryElement = countAndArbitraryElementA[1] if countAndArbitraryElementB[1] is None else countAndArbitraryElementB[1]
      return (newCount, newArbitraryElement)
    
    resultStatistics = (satisfyingAssignments
      .map(lambda elt: (1, elt))
      .reduce((0, None), reduceResultStatistics))
    
    def buildSolution():
      numSatisfyingAssignments, arbitrarySatisfyingAssignment = resultStatistics
      #print "%d out of %d satisfying assignments." % (numSatisfyingAssignments, numSamples)
      if numSatisfyingAssignments*1.0/numSamples <= 0.0002 and numSatisfyingAssignments != 0:
        print "problem difficulty = " + str(numSatisfyingAssignments*1.0/numSamples)
      
      if arbitrarySatisfyingAssignment > -1:
        return KsatSolution.success(arbitrarySatisfyingAssignment)
      else:
        return KsatSolution.failure()
    
    return onMaster(problem.comm(), buildSolution)