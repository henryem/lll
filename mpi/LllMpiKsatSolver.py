from MpiKsatSolver import MpiKsatSolver

class LllSolverState(object):
  def __init__(self, problem, graph, initialAssignment):
    # Immutable.
    self.problem = problem
    # Immutable.
    self.graph = graph
    # Changes as the solver runs.
    self.initialAssignment = initialAssignment

def initializeLllSolverState(problem):
  pass #FIXME

# A class of LLL algorithms for solving distributed k-SAT problems.  Solvers
# are parameterized by a method for finding independent sets in clause
# dependency graphs.
class LllKsatSolver(MpiKsatSolver):
  def __init__(self):
    super(LllKsatSolver, self).__init__()
  
  def solve(self, problem):
    state = initializeLllSolverState(problem)
    #FIXME