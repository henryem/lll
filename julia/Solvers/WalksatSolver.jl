export WalksatSolver, solve

using Problems

# An implementation of the WALKSAT algorithm.
immutable WalksatSolver <: Solver{KsatProblem}
end

function solve(this:: WalksatSolver, problem:: KsatProblem)
  const n = problem.numVariables
  const maxNumAssignments = 3*n #FIXME
  assignment = uniformRandomBinaryAssignment(n)
  annotatedProblem = annotateSatProblem(problem, assignment)
  # println("Initially unsatisfied clauses: $(unsatisfiedClauses(annotatedProblem))")
  for assignmentIdx in 1:numAssignments
    # Pick an arbitrary unsatisfied clause.  The first one will do.
    unsat = unsatisfiedClauses(annotatedProblem)
    if isempty(unsat)
      println("Found successful solution after $(assignmentIdx) flips.")
      return successfulSolution(annotatedProblem.currentAssignment)
    end
    println("Unsatisfied clauses at round $(assignmentIdx): $(unsatisfiedClauses(annotatedProblem))")
    clauseIdx = first(unsat)
    clause = problem.clauses[clauseIdx]
    variableIdx = argmax(1:k) do variableInClauseIdx
      
      #FIXME: Return # of satisfied clauses.
    end
    variable = vbl(clause)[variableInClauseIdx]
    # println("Flipping variable $(variable) ($(variableInClauseIdx) in clause $(clauseIdx)/$(numClauses(problem)) $(clause))")
    currentValue = annotatedProblem.currentAssignment[variable]
    updateAssignment!(annotatedProblem, variable, currentValue, !currentValue)
  end
  unsuccessfulSolution(BinaryAssignment)
end