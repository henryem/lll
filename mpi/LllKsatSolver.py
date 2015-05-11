from MpiKsatSolver import MpiKsatSolver
from MpiUtils import onMaster
import IndependentSetFinder
import MpiGraph
import MpiCollection
import MpiKsatAssignment
import KsatSolution
import Utils
import CollectionUtils
import datetime

# A class of LLL algorithms for solving distributed k-SAT problems.  Solvers
# are parameterized by a method for finding independent sets in clause
# dependency graphs.
class LllKsatSolver(MpiKsatSolver):
  def __init__(self, independentSetFinder):
    self.independentSetFinder = independentSetFinder
    super(LllKsatSolver, self).__init__()
  
  def solve(self, rand, problem):
    comm = problem.comm()
    n = problem.numVariables

    
    #broadcastStartTime = now()
    broadcastStartTime = datetime.datetime.now()
    broadcastProblem = problem.toBroadcast()
    broadcastEndTime = datetime.datetime.now()

    #graphCreationStartTime = now()
    graphCreationStartTime = datetime.datetime.now()
    graph = broadcastProblem.toDependencyGraph(comm)
    graphCreationEndTime = datetime.datetime.now()
    
    currentAssignment = MpiKsatAssignment.uniformRandomMpiKsatAssignment(comm, rand, n)
    maxNumIterations = self.independentSetFinder.calculateNumIterations(problem, graph)
    if comm.rank == 0: print "Solving problem with %s iterations." % maxNumIterations

    #initialMarkingsStartTime = now()
    initialMarkingsStartTime = datetime.datetime.now()
    independentSetFunc = self.independentSetFinder.buildFinderFunc(rand, graph)
    initialMarkingsEndTime = datetime.datetime.now()


    findIndependentSetAndResampleTotalTime = datetime.timedelta()
    broadcastModifiedVariablesTotalTime = datetime.timedelta()

    for i in xrange(maxNumIterations):
      # At the beginning of each iteration of this loop, @currentAssignment
      # is consistent across processors.
      localAssignment = currentAssignment.localAssignment()
      unsatSubgraph = graph.filter(lambda clauseIdx: not localAssignment.satisfiesClause(broadcastProblem.clausesByIdx[clauseIdx]))
      # print "%d unsatisfied clauses on iteration %d on machine %d: %s." % (CollectionUtils.iterlen(unsatSubgraph.nodesIterator().localElements()), i, comm.rank, {clauseIdx: broadcastProblem.clausesByIdx[clauseIdx] for clauseIdx in unsatSubgraph.nodesIterator().localElements()})
      localIndependentSet = independentSetFunc(unsatSubgraph)
      locallyModifiedVariables = MpiCollection.dictFromLocal(comm, {})
      #FIXME
      localIndependentSetSize = 0
      
      #findIndependentSetAndResampleStartTime = now()
      findIndependentSetAndResampleStartTime = datetime.datetime.now()
      for clauseIdx in localIndependentSet.localElements():
        clause = broadcastProblem.clausesByIdx[clauseIdx]
        #TODO: Only communicate modified variables to machines that need them.
        # For now we assume all machines need to see all modified variables,
        # which is true when m*k/p >> n (i.e. when the number of literals per
        # machine is large).
        updates = {variable: Utils.randBit(rand) for variable in clause.literals}
        locallyModifiedVariables.localDict().update(updates)
        localIndependentSetSize += 1
      findIndependentSetAndResampleTotalTime += datetime.datetime.now() - findIndependentSetAndResampleStartTime
      # print "Using an independent set of size %d on iteration %d on machine %d." % (localIndependentSetSize, i, comm.rank)
      #TODO: Probably inefficient serialization here.  Should serialize as
      # a list of ints and a list of bools.

      #broadcastModifiedVariablesStartTime = now()
      broadcastModifiedVariablesStartTime = datetime.datetime.now()
      allModifiedVariables = locallyModifiedVariables.collectEverywhere()
      broadcastModifiedVariablesTotalTime += datetime.datetime.now() - broadcastModifiedVariablesStartTime

      if len(allModifiedVariables) == 0:
        if comm.rank == 0:
          print "\nBroadcast time = " + str((broadcastEndTime - broadcastStartTime).total_seconds())
          print "Graph creation time = " + str((graphCreationEndTime - graphCreationStartTime).total_seconds())
          print "Initial markings time = " + str((initialMarkingsEndTime - initialMarkingsStartTime).total_seconds())
          print "Find independentSet and resample time = "+ str(findIndependentSetAndResampleTotalTime.total_seconds())
          print "Boardcast modified variables time = "+ str(broadcastModifiedVariablesTotalTime.total_seconds())
          print "\n"
          print "Finished after %d iterations." % i
        return onMaster(comm, lambda : KsatSolution.success(localAssignment))
      # Update modified variables from everywhere.
      for var, value in allModifiedVariables.items():
        localAssignment.values[var] = value
    return onMaster(comm, lambda : KsatSolution.failure())