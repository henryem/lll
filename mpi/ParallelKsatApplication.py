import argparse
from mpi4py import MPI
import numpy as np
import datetime

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

  #NOTE: The solver will perform differently for different numbers of machines,
  # even if the randoms seed is the same.
  solverRand = np.random.RandomState(args.solverSeed if args.solverSeed is not None else None)

  wholeSolveStartTime = datetime.datetime.now()
  solution = solver.solve(solverRand, problem)
  wholeSolveEndTime = datetime.datetime.now()

  #if comm.rank == 0:
  #  print "\nTotal Solving Time is " + str((wholeSolveEndTime - wholeSolveStartTime).total_seconds()) + "\n"
  
  #if comm.rank == 0:
    #print "Finished running solver %s; found %s" % (args.solver, solution)
  
  satisfactionCheck = problem.isSatisfiedBy(solution)
  if comm.rank == 0:
    if satisfactionCheck != solution.isSuccessful():
      print "Solution check failure: Solver claimed success was %s but was %s!" % (solution.isSuccessful(), satisfactionCheck)

if __name__ == "__main__":
  run()