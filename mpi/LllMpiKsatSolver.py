from MpiKsatSolver import MpiKsatSolver
from MpiUtils import onMaster
import IndependentSetFinder
import MpiGraph
import MpiKsatAssignment
import KsatSolution

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
    graph = MpiGraph.makeKsatDependencyGraph(problem)
    currentAssignment = MpiKsatAssignment.uniformRandomMpiKsatAssignment(rand, n)
    maxNumIterations = self.independentSetFinder.calculateNumIterations(problem, graph)
    independentSetFunc = self.independentSetFunc.buildFinderFunc(rand, graph)
    for i in xrange(maxNumIterations):
      # At the beginning of each iteration of this loop, @currentAssignment
      # is consistent across processors.
      #FIXME: Implement.
      unsatisfiedClauses = localUnsatisfiedClauses(problem, currentAssignment)
      if len(unsatisfiedClauses) == 0:
        return onMaster(comm, lambda : KsatSolution.success(currentAssignment.localAssignment()))
      unsatSubgraph = MpiGraph.inducedSubgraph(unsatisfiedClauses)
      localIndependentSet = independentSetFunc(unsatSubgraph)
      localClausesByIdx = problem.localClausesByIdx()
      #FIXME: Weird initialization.
      locallyModifiedVariables = MpiDict(comm, MpiChunks(comm, {}))
      for clauseIdx in localIndependentSet:
        clause = localClausesByIdx[clauseIdx]
        #TODO: Only communicate modified variables to machines that need them.
        # For now we assume all machines need to see all modified variables,
        # which is true when m*k/p >> n (i.e. when the number of literals per
        # machine is large).
        updates = {variable: rand.randint(0, 2) for variable in clause.literals}
        locallyModifiedVariables.localDict().update(updates)
      #FIXME: Implement on MpiDict.
      allModifiedVariables = locallyModifiedVariables.collectEverywhere()
      #FIXME: Update currentAssignment from dict.
    return onMaster(comm, lambda : KsatSolution.failure())