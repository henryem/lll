

def isSatisfied(clause, assignment):
	for (variableIdx, variable) in enumerate(clause.variables):
		value = assignment[variable]
		if clause.signs[variableIdx] == value:
			return True
	return False

def checkSuccess(assignment, problem):
	for clause in problem.clauses:
		if isSatisfied(clause,assignment) == False:
			return False
	return True
