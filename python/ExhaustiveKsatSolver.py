import numpy as np
from KsatProblem import checkSuccess
class ExhaustiveKsatSolver():
	@staticmethod
	def solve(problem):
		n = problem.numVariables
		assignment = [False] * n
	  	satisfyingAssignment = []
	  	numSatisfyingSolutions = 0
	  	numPotentialSolutions = 2**n
	  	for binaryAssignment in range(0,numPotentialSolutions):
	  		for variableIdx in range(0,n):
	  			bit = (binaryAssignment >> (variableIdx)) & 0x1
	  			if bit == 0:
	  				assignment[variableIdx] = False
	  			else:
	  				assignment[variableIdx] = True
	  		if checkSuccess(assignment, problem):
	  			if numSatisfyingSolutions == 0:
	  				satisfyingAssignment.extend(assignment)
	  			numSatisfyingSolutions += 1
	  	return {"satisfyingAssignment":satisfyingAssignment, "isSuccessful": numSatisfyingSolutions > 0, "numSatisfyingSolutions":numSatisfyingSolutions, "numPotentialSolutions": numPotentialSolutions}

