

def isSatisfied(clause, assignment):
	# print clause.variables
	# print clause.signs
	# print assignment
	for (variableIdx, variable) in enumerate(clause.variables):
		# print variableIdx, variable
		# print assignment[variable]
		value = assignment[variable]
		if clause.signs[variableIdx] == value:
			# print "satisfied"
			return True
	return False

def checkSuccess(assignment, problem):
	for clause in problem.clauses:
		if isSatisfied(clause,assignment) == False:
			return False
	return True

def isSuccessful(ksatSolution):
	return ksatSolution.isSuccessful
