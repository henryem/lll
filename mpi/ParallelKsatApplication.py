import argparse
from mpi4py import MPI
import numpy as np

import MpiKsatProblem
import ExhaustiveMpiKsatSolver
import LllKsatSolver
import IndependentSetFinder

def parseArgs():
  parser = argparse.ArgumentParser()
  parser.add_argument('--generator', action='store',
                     help='a Python expression yielding the KsatGenerator to run')
  parser.add_argument('--solver', action='store',
                     help='a Python expression yielding the MpiKsatSolver to use')
  parser.add_argument('--problemSeed', action='store', default=None, type=int,
                     help='the random seed to use when generating the problem')
  parser.add_argument('--solverSeed', action='store', default=None, type=int,
                     help='the random seed to use when solving the problem')
  return parser.parse_args()

def run():
  args = parseArgs()
  comm = MPI.COMM_WORLD
  problemRand = np.random.RandomState(args.problemSeed if args.problemSeed is not None else None)
  problem = eval(args.generator).generate(comm, problemRand)
  solver = eval(args.solver)

  solverRand = np.random.RandomState(args.solverSeed if args.solverSeed is not None else None)
  solution = solver.solve(solverRand, problem)
  
  if comm.rank == 0:
    print "Finished running solver %s; found %s" % (args.solver, solution)

if __name__ == "__main__":
  run()