export AnnotatedSatProblem, unsatisfiedClauses, variablesToClauses, annotateSatProblem, updateAssignment!, registerUpdate!, AnnotatedSatSolution, isSuccessful

using Problems

# A k-SAT problem with some extra metadata useful for an iterative solver,
# including a current assignment to the variables.
type AnnotatedSatProblem
  problem:: SatLikeProblem
  # Mutable.
  currentAssignment:: BinaryAssignment
  variablesToClauses:: Dict{Int64, Set{Int64}}
  # Mutable.
  unsatisfiedClauses:: Set{Int64} #TODO: Use IntSet instead?
end

function unsatisfiedClauses(this:: AnnotatedSatProblem)
  this.unsatisfiedClauses
end

function variablesToClauses(this:: AnnotatedSatProblem)
  this.variablesToClauses
end

function annotateSatProblem(p:: SatLikeProblem, initialAssignment:: BinaryAssignment)
  variablesToClauses = Dict{Int64, Set{Int64}}()
  unsatisfiedClauses = Set{Int64}()
  for (clauseIdx, clause) in enumerate(constraints(p))
    for variable in vbl(clause)
      if !haskey(variablesToClauses, variable)
        variablesToClauses[variable] = Set(clauseIdx)
      else
        push!(variablesToClauses[variable], clauseIdx)
      end
    end
    if !isSatisfied(clause, initialAssignment)
      push!(unsatisfiedClauses, clauseIdx)
    end
  end
  AnnotatedSatProblem(p, initialAssignment, variablesToClauses, unsatisfiedClauses)
end

# Update @updatedVariable to @newValue, updating the list of unsatisfied
# clauses accordingly.
function updateAssignment!(this:: AnnotatedSatProblem, updatedVariable:: Int64, oldValue:: Bool, newValue:: Bool)
  if (oldValue == newValue)
    return
  end
  this.currentAssignment.vars[updatedVariable] = newValue
  #TODO: There may be a more efficient way to do these updates.
  for affectedClauseIdx in this.variablesToClauses[updatedVariable]
    affectedClause = constraints(this.problem)[affectedClauseIdx]
    if isSatisfied(affectedClause, this.currentAssignment)
      delete!(this.unsatisfiedClauses, affectedClauseIdx)
    else
      push!(this.unsatisfiedClauses, affectedClauseIdx)
    end
  end
end

# Update the list of unsatisfied clauses to reflect that the variables in
# @possiblyUpdatedVariables might have been modified in this.currentAssignment.
function registerUpdate!(this:: AnnotatedSatProblem, possiblyUpdatedVariables:: AbstractVector{Int64})
  affectedClauses = union(map(v -> this.variablesToClauses[v], possiblyUpdatedVariables)...)
  for affectedClauseIdx in affectedClauses
    affectedClause = constraints(this.problem)[affectedClauseIdx]
    if isSatisfied(affectedClause, this.currentAssignment)
      delete!(this.unsatisfiedClauses, affectedClauseIdx)
    else
      push!(this.unsatisfiedClauses, affectedClauseIdx)
    end
  end
end


# A k-SAT solution with some extra information about the problem, which can be
# populated by (for example) an exhaustive solver.
immutable AnnotatedSatSolution <: ProblemSolution
  assignment:: BinaryAssignment
  isSuccessful:: Bool
  numSatisfyingSolutions:: Int64
  numPotentialSolutions:: Int64
end

function Problems.isSuccessful(this:: AnnotatedSatSolution)
  return this.isSuccessful
end