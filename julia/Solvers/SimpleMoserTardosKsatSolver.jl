export SimpleMoserTardosKsatSolver, solve

using Problems

immutable SimpleMoserTardosKsatSolver <: Solver{KsatProblem}
end

function solve(this:: SimpleMoserTardosKsatSolver, problem:: KsatProblem)
  # See Moser and Tardos 2010, algorithm 1.1.
  const n = problem.numVariables
  const maxNumIterations = 1000 #FIXME
  println("Using at most $(maxNumIterations) iterations for $(problem.k)-SAT problem with $(n) variables and $(numClauses(problem)) clauses.")
  println("Problem: $(string(problem))")
  assignment = uniformRandomAssignment(n)
  annotatedProblem = annotateKsatProblem(problem, assignment)
  for i = 1:maxNumIterations
    const unsat = unsatisfiedClauses(annotatedProblem)
    if isempty(unsat)
      println("Found successful solution after $(i) iterations.")
      return toSuccessfulSolution(annotatedProblem)
    end
    const clauseIdx = first(unsat)
    const clause = problem.clauses[clauseIdx]
    for variable in clause.variables
      annotatedProblem.currentAssignment[variable] = randbool()
    end
    registerUpdate!(annotatedProblem, clause.variables)
  end
  unsuccessfulKsatSolution(n)
end
