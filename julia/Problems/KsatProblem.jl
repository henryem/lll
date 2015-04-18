export KsatProblem, SatClause, KsatSolution, isSuccessful, unsuccessfulKsatSolution, KsatAssignment, isSatisfied, checkSuccess

immutable KsatProblem <: Problem
  k:: Int64
  numVariables:: Int64
  clauses:: AbstractVector{SatClause}
end

immutable SatClause
  variables:: AbstractVector{Int64}
  signs:: AbstractVector{Bool}
end

immutable KsatSolution <: Solution
  assignment:: KsatAssignment
  isSuccessful:: Bool
end

function isSuccessful(this:: KsatSolution)
  return this.isSuccessful
end

function unsuccessfulKsatSolution(numVariables:: Int64)
  return KsatSolution(map(i -> false, 1:numVariables), false)
end

typealias KsatAssignment AbstractVector{Bool}

function isSatisfied(clause:: SatClause, assignment:: KsatAssignment)
  for (variableIdx, variable) in enumerate(clause.variables)
    const value = assignment[variable]
    if (clause.signs[variableIdx] ? !value : value)
      return false
    end
  end
  return true
end

function checkSuccess(this:: KsatAssignment, p:: KsatProblem)
  for clause in p.clauses
    if !isSatisfied(clause, this)
      return false
    end
  end
  return true
end