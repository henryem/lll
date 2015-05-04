import random

class SatClause():
	def __init__(self):
		self.variables = []
		self.signs = []

class KsatProblem():
	def __init__(self):
		self.k = None
		self.numVariables = 0
		self.clauses = []

class RandomKsat():
	@staticmethod
	def generate(k, numVariables, numClauses):
		ksatProblem = KsatProblem()
		ksatProblem.k = k
		ksatProblem.numVariables = numVariables
		for i in range(numClauses):
			satClause = SatClause()
			satClause.variables = random.sample(xrange(numVariables),k)
			for i in range(k):
				satClause.signs.append(random.choice([True, False]))
			ksatProblem.clauses.append(satClause)
		return ksatProblem
