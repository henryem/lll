from MpiKsatSolver import MpiKsatSolver
from MpiUtils import onMaster
import IndependentSetFinder
import MpiGraph
import MpiKsatAssignment
import KsatSolution
import Utils

# The set of indices of local clauses in @problem that are unsatisfied under
# @assignment.
def localUnsatisfiedClauses(problem, assignment):
  localClausesByIdx = problem.localClausesByIdx()
  localAssignment = assignment.localAssignment()
  return set(clauseIdx for clauseIdx, clause in problem.localClausesByIdx() if localAssignment.satisfiesClause(clause))

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
      unsatisfiedClauses = localUnsatisfiedClauses(problem, currentAssignment)
      if len(unsatisfiedClauses) == 0:
        return onMaster(comm, lambda : KsatSolution.success(currentAssignment.localAssignment()))
      #FIXME: Implement.
      unsatSubgraph = MpiGraph.inducedSubgraph(unsatisfiedClauses)
      #FIXME: Implement.
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
        updates = {variable: Utils.randBit(rand) for variable in clause.literals}
        locallyModifiedVariables.localDict().update(updates)
      #TODO: Probably inefficient serialization here.  Should serialize as
      # a list of ints and a list of bools.
      allModifiedVariables = locallyModifiedVariables.collectEverywhere()
      # Update modified variables from everywhere.
      localAssignment = currentAssignment.localAssignment()
      for var, value in allModifiedVariables:
        localAssignment[var] = value
    return onMaster(comm, lambda : KsatSolution.failure())