import argparse
from mpi4py import MPI
import numpy as np

import MpiKsatProblem
import ExhaustiveMpiKsatSolver
import LllMpiKsatSolver

def parseArgs():
  parser = argparse.ArgumentParser()
  parser.add_argument('--generator', action='store',
                     help='a Python expression yielding the KsatGenerator to run')
  parser.add_argument('--solver', action='store',
                     help='a Python expression yielding the MpiKsatSolver to use')
  parser.add_argument('--seed', action='store', default=None, type=int,
                     help='the random seed to use')
  return parser.parse_args()

def run():
  args = parseArgs()
  comm = MPI.COMM_WORLD
  rand = np.random.RandomState(args.seed if args.seed is not None else None)
  problem = eval(args.generator).generate(comm, rand)
  solver = eval(args.solver)
  
  solution = solver.solve(rand, problem)
  
  if comm.rank == 0:
    print "Finished running solver %s; found %s" % (args.solver, solution)

if __name__ == "__main__":
  run()