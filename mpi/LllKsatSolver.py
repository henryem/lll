from MpiKsatSolver import MpiKsatSolver
from MpiUtils import onMaster
import IndependentSetFinder
import MpiGraph
import MpiCollection
import MpiKsatAssignment
import KsatSolution
import Utils

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
    broadcastProblem = problem.toBroadcast()
    graph = broadcastProblem.toDependencyGraph(comm)
    currentAssignment = MpiKsatAssignment.uniformRandomMpiKsatAssignment(comm, rand, n)
    maxNumIterations = self.independentSetFinder.calculateNumIterations(problem, graph)
    if comm.rank == 0: print "Solving problem %s... with %s iterations." % (problem, maxNumIterations)
    independentSetFunc = self.independentSetFinder.buildFinderFunc(rand, graph)
    for i in xrange(maxNumIterations):
      # At the beginning of each iteration of this loop, @currentAssignment
      # is consistent across processors.
      localAssignment = currentAssignment.localAssignment()
      unsatSubgraph = graph.filter(lambda clauseIdx: not localAssignment.satisfiesClause(broadcastProblem.clausesByIdx[clauseIdx]))
      localIndependentSet = independentSetFunc(unsatSubgraph)
      locallyModifiedVariables = MpiCollection.dictFromLocal(comm, {})
      for clauseIdx in localIndependentSet.localElements():
        clause = broadcastProblem.clausesByIdx[clauseIdx]
        #TODO: Only communicate modified variables to machines that need them.
        # For now we assume all machines need to see all modified variables,
        # which is true when m*k/p >> n (i.e. when the number of literals per
        # machine is large).
        updates = {variable: Utils.randBit(rand) for variable in clause.literals}
        locallyModifiedVariables.localDict().update(updates)
      #TODO: Probably inefficient serialization here.  Should serialize as
      # a list of ints and a list of bools.
      allModifiedVariables = locallyModifiedVariables.collectEverywhere()
      if len(allModifiedVariables) == 0:
        print "Finished after %d iterations." % i
        return onMaster(comm, lambda : KsatSolution.success(localAssignment))
      # Update modified variables from everywhere.
      for var, value in allModifiedVariables.items():
        localAssignment.values[var] = value
    return onMaster(comm, lambda : KsatSolution.failure())