export AnnotatedKsatProblem, unsatisfiedClauses, variablesToClauses, toSuccessfulSolution, toUnsuccessfulSolution, annotateKsatProblem, updateAssignment!, registerUpdate!, AnnotatedKsatSolution, isSuccessful

using Problems

# A k-SAT problem with some extra metadata useful for an iterative solver,
# including a current assignment to the variables.
type AnnotatedKsatProblem
  problem:: KsatProblem
  # Mutable.
  currentAssignment:: KsatAssignment
  variablesToClauses:: Dict{Int64, Set{Int64}}
  # Mutable.
  unsatisfiedClauses:: Set{Int64} #TODO: Use IntSet instead?
end

function unsatisfiedClauses(this:: AnnotatedKsatProblem)
  this.unsatisfiedClauses
end

function variablesToClauses(this:: AnnotatedKsatProblem)
  this.variablesToClauses
end

function toSuccessfulSolution(this:: AnnotatedKsatProblem)
  #TODO: Assert unsatisfiedClauses isempty.
  KsatSolution(this.currentAssignment, true)
end

function toUnsuccessfulSolution(this:: AnnotatedKsatProblem)
  KsatSolution(this.currentAssignment, false)
end

function annotateKsatProblem(p:: KsatProblem, initialAssignment:: KsatAssignment)
  variablesToClauses = Dict{Int64, Set{Int64}}()
  unsatisfiedClauses = Set{Int64}()
  for (clauseIdx, clause) in enumerate(p.clauses)
    for variable in clause.variables
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
  AnnotatedKsatProblem(p, initialAssignment, variablesToClauses, unsatisfiedClauses)
end

# Update @updatedVariable to @newValue, updating the list of unsatisfied
# clauses accordingly.
function updateAssignment!(this:: AnnotatedKsatProblem, updatedVariable:: Int64, oldValue:: Bool, newValue:: Bool)
  if (oldValue == newValue)
    return
  end
  this.currentAssignment[updatedVariable] = newValue
  #TODO: There may be a more efficient way to do these updates.
  for affectedClauseIdx in this.variablesToClauses[updatedVariable]
    affectedClause = this.problem.clauses[affectedClauseIdx]
    if isSatisfied(affectedClause, this.currentAssignment)
      delete!(this.unsatisfiedClauses, affectedClauseIdx)
    else
      push!(this.unsatisfiedClauses, affectedClauseIdx)
    end
  end
end

# Update the list of unsatisfied clauses to reflect that the variables in
# @possiblyUpdatedVariables might have been modified in this.currentAssignment.
function registerUpdate!(this:: AnnotatedKsatProblem, possiblyUpdatedVariables:: AbstractVector{Int64})
  affectedClauses = union(map(v -> this.variablesToClauses[v], possiblyUpdatedVariables)...)
  for affectedClauseIdx in affectedClauses
    affectedClause = this.problem.clauses[affectedClauseIdx]
    if isSatisfied(affectedClause, this.currentAssignment)
      delete!(this.unsatisfiedClauses, affectedClauseIdx)
    else
      push!(this.unsatisfiedClauses, affectedClauseIdx)
    end
  end
end

# A k-SAT solution with some extra information about the problem, which can be
# populated by (for example) an exhaustive solver.
immutable AnnotatedKsatSolution <: Solution
  assignment:: KsatAssignment
  isSuccessful:: Bool
  numSatisfyingSolutions:: Int64
  numPotentialSolutions:: Int64
end

function Problems.isSuccessful(this:: AnnotatedKsatSolution)
  return this.isSuccessful
end