export AnnotatedKsatProblem, unsatisfiedClauses, variablesToClauses, toSuccessfulSolution, annotateKsatProblem, updateAssignment!

using Problem

type AnnotatedKsatProblem
  problem:: KsatProblem
  # Mutable.
  currentAssignment:: KsatAssignment
  variablesToClauses:: Dict{Int64, Int64}
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

function annotateKsatProblem(p:: KsatProblem, initialAssignment:: KsatAssignment)
  variablesToClauses = Dict{Int64, Int64}()
  unsatisfiedClauses = Set{Int64}()
  for (clauseIdx, clause) in enumerate(p.clauses)
    for variable in clause
      if !haskey(variablesToClauses, variable)
        variablesToClauses[variable] = [clauseIdx]
      else
        push!(variablesToClauses[variable], clauseIdx)
    end
    if !isSatisfied(clause, initialAssignment)
      push!(unsatisfiedClauses, clauseIdx)
    end
  end
  AnnotatedKsatProblem(p, initialAssignment, variablesToClauses, unsatisfiedClauses)
end

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