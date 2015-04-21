export RandomWalkKsatSolver, solve

using Problems

immutable RandomWalkKsatSolver <: Solver{KsatProblem}
  # An upper bound on the probability that we fail to find a satisfying
  # solution given that one exists.  This, along with the problem size,
  # determines the maximum number of iterations taken to find a solution.
  # When no satisfying solution exists,
  # the solver will always take that many iterations, since this solver
  # produces no certificate of failure.
  failureProbability:: Float64
end

function solve(this:: RandomWalkKsatSolver, problem:: KsatProblem)
  # See Mitzenmacher and Upfal 2005, section 7.1.2, algorithm 7.3.
  const n = problem.numVariables
  const numAssignmentsPerAttempt = 3*n
  const expectedNumStepsRequired = n^1.5 * (4.0/3.0)^n
  const numAttempts = int(ceil(2*(-1)*log2(this.failureProbability)*expectedNumStepsRequired))
  println("Making $(numAttempts) attempts for $(problem.k)-SAT problem with $(n) variables and $(length(problem.clauses)) clauses, with $(numAssignmentsPerAttempt) assignments per attempt.")
  println("Problem: $(string(problem))")
  findSolution(numAttempts, problem)
end

function findSolution(numAttempts:: Int64, problem:: KsatProblem)
  for attemptIdx in 1:numAttempts
    solution = solve(SimpleRandomKsatSolver(), problem)
    if isSuccessful(solution)
      println("Found successful solution after $(attemptIdx) attempts.")
      return solution
    end
    # println("Failed attempt $(attemptIdx), with final solution $(solution.assignment).")
  end
  unsuccessfulKsatSolution(problem.numVariables)
end

immutable SimpleRandomKsatSolver <: Solver{KsatProblem}
end

function solve(this:: SimpleRandomKsatSolver, problem:: KsatProblem)
  # See Mitzenmacher and Upfal 2005, section 7.1.2, algorithm 7.3.
  const n = problem.numVariables
  const numAssignments = 3*n
  assignment = uniformRandomAssignment(n)
  annotatedProblem = annotateKsatProblem(problem, assignment)
  # println("Initially unsatisfied clauses: $(unsatisfiedClauses(annotatedProblem))")
  for assignmentIdx in 1:numAssignments
    # Pick an arbitrary unsatisfied clause.  The first one will do.
    unsat = unsatisfiedClauses(annotatedProblem)
    if isempty(unsat)
      println("Found successful solution after $(assignmentIdx) flips.")
      return toSuccessfulSolution(annotatedProblem)
    end
    # println("Unsatisfied clauses at round $(assignmentIdx): $(unsatisfiedClauses(annotatedProblem))")
    clauseIdx = first(unsat)
    clause = problem.clauses[clauseIdx]
    variableInClauseIdx = rand(1:problem.k)
    variable = clause.variables[variableInClauseIdx]
    # println("Flipping variable $(variable) ($(variableInClauseIdx) in clause $(clauseIdx)/$(length(problem.clauses)) $(clause))")
    currentValue = annotatedProblem.currentAssignment[variable]
    updateAssignment!(annotatedProblem, variable, currentValue, !currentValue)
  end
  toUnsuccessfulSolution(annotatedProblem)
end
