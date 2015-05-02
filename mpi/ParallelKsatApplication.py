import argparse
from mpi4py import MPI

import MpiKsatProblem

def parseArgs():
  parser = argparse.ArgumentParser()
  parser.add_argument('--generator', action='store',
                     help='a Python expression yielding the KsatGenerator to run')
  parser.add_argument('--solver', action='store',
                     help='a Python expression yielding the MpiKsatSolver to use')
  parser.add_argument('--seed', action='store', default=0, type=int
                     help='the random seed to use')
  return parser.parse_args()

def run():
  args = parseArgs()
  comm = MPI.COMM_WORLD
  seed = args.seed
  problem = eval(args.generator).generate(comm, seed)

  #FIXME
  if comm.rank == 0:
    print "Collecting generated problem on processor 0..."
  clauses = p.distributedClauses.collect()
  if comm.rank == 0:
    print "Collected generated problem on processor 0."
    print ",".join(str(clause) for clause in clauses)
    
  solver = eval(args.solver)
  solution = solver.solve(problem)
  
  if comm.rank == 0:
    if isSuccessful(solution):
      print "Successful solution found: %s" % solution
    else:
      print "No solution found."

if __name__ == "__main__":
  run()