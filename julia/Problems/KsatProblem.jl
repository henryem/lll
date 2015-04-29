export KsatProblem, numClauses, SatClause, KsatSolution, isSuccessful, unsuccessfulKsatSolution, KsatAssignment, isSatisfied, checkSuccess, uniformRandomAssignment

# A disjunction of variables.
immutable SatClause
  variables:: AbstractVector{Int64}
  signs:: AbstractVector{Bool}
end

function Base.string(this:: SatClause)
  join(
    map(1:length(this.variables)) do varIdx
      const prefix = this.signs[varIdx] ? "" : "!"
      "$(prefix)$(this.variables[varIdx])"
    end,
    "|")
end

# A conjunction of disjunctive clauses (an AND of numVariables clauses, each
# clause being an OR of k variables).
immutable KsatProblem <: Problem
  k:: Int64
  numVariables:: Int64
  clauses:: AbstractVector{SatClause}
end

const MAX_DISPLAYED_LITERALS = 200
function Base.string(this:: KsatProblem)
  const maxDisplayedClauses = int(MAX_DISPLAYED_LITERALS / this.k)
  const numDisplayedClauses = min(maxDisplayedClauses, numClauses(this))
  const clausesString = join(map(c -> "($(string(c)))", this.clauses[1:numDisplayedClauses]), "&")
  "$(this.k)-SAT problem $(clausesString)$(numDisplayedClauses < numClauses(this) ? "..." : "")"
end

function numClauses(this:: KsatProblem)
  length(this.clauses)
end


typealias KsatAssignment AbstractVector{Bool}

function isSatisfied(clause:: SatClause, assignment:: KsatAssignment)
  # A clause is disjunctive -- an OR of variables.
  for (variableIdx, variable) in enumerate(clause.variables)
    const value = assignment[variable]
    if clause.signs[variableIdx] == value
      return true
    end
  end
  return false
end

function checkSuccess(this:: KsatAssignment, p:: KsatProblem)
  for clause in p.clauses
    if !isSatisfied(clause, this)
      return false
    end
  end
  return true
end

function uniformRandomAssignment(numVariables:: Int64)
  randbool(numVariables)
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

