export RandomWalkKsatSolver, solve

using Problem

immutable RandomWalkKsatSolver <: Solver{KsatProblem}
  failureProbability:: Float64
end

function solve(this:: RandomWalkKsatSolver, problem:: KsatProblem)
  # See Mitzenmacher and Upfal 2005, section 7.1.2, algorithm 7.3.
  const n = problem.numVariables
  const numAssignmentsPerAttempt = 3*n
  const expectedNumStepsRequired = n^1.5 * (4.0/3.0)^n
  const numAttempts = ceil(2*-1*log2(this.failureProbability)*expectedNumStepsRequired)
  findSolution(numAttempts, problem)
end

function findSolution(numAttempts:: Int64, problem:: KsatProblem)
  for attemptIdx in 1:numAttempts
    solution = solve(SimpleRandomKsatSolver(), problem)
    if isSuccessful(solution)
      return solution
    end
  end
  unsuccessfulKsatSolution(problem.numVariables)
end

immutable SimpleRandomKsatSolver <: Solver{KsatProblem}
end

function solve(this:: SimpleRandomKsatSolver, problem:: KsatProblem)
  # See Mitzenmacher and Upfal 2005, section 7.1.2, algorithm 7.3.
  const n = problem.numVariables
  const numAssignments = 3*n
  annotatedProblem = annotateKsatProblem(problem)
  for assignmentIdx in 1:numAssignments
    # Pick an arbitrary unsatisfied clause.  The first one will do.
    unsat = unsatisfiedClauses(annotatedProblem)
    if isempty(unsat)
      return toSuccessfulSolution(annotatedProblem)
    end
    clauseIdx = start()
    clause = problem.clauses[clauseIdx]
    variable = clause.variables[rand(1:problem.k)]
    currentValue = annotatedProblem.currentAssignment[variable]
    updateAssignment!(annotatedProblem, variable, currentValue, !currentValue)
  end
  unsuccessfulKsatSolution(problem.numVariables)
end