from ExhaustiveKsatSolver import ExhaustiveKsatSolver
import argparse
from RandomKsat import RandomKsat

def compareGroundTruth(problem):
	print "Using exhaustive search to find a solution"
	trueSolution = ExhaustiveKsatSolver.solve(problem)

	# if (isSuccessful(trueSolution)):
	# 	print "The problem has a solution: "+str(trueSolution)
	# else:
	# 	print "The problem has no solution."
 
def parseArgs():
	parser = argparse.ArgumentParser()
	parser.add_argument("-s", "--solver", help="the Solver to use, a string")
	parser.add_argument("-d", "--data_generator", help="the DataGenerator to use, a string")
	parser.add_argument("-g", "--compare_ground_truth", action="store_true", help="whether to solve exhaustively to compare with ground truth")
	parser.add_argument("-e", "--seed", type=int, help= "the random seed")
	return parser.parse_args()
	
def run():
	args = parseArgs()
	problemGenerator = args.data_generator
	solver = args.solver
	
	#Get problem arguments for Ksat Problem generator
	problemArg = problemGenerator[problemGenerator.find("(")+1:problemGenerator.find(")")]
	problemArg = [int(s) for s in problemArg.split(",") if s.isdigit()]
	
	#Get Ksat Problems
	ksatProblem = RandomKsat.generate(problemArg[0],problemArg[1],problemArg[2])

	if args.compare_ground_truth:
		compareGroundTruth(ksatProblem)
#	solution = solve(solver, problem)
#	if isSuccessful(solution):
#		print "Successful solution found for "+problem[k]+"-SAT problem with n="+problem[numVariables]+", numClauses="+len(problem[clauses])
#		print "Check: "+ checkSuccess(solution[assignment], problem)
#		print "Solution: "+ solution.assignment

run()