using GeneratedData, Problem, Solver

function run()
  const k = 3
  const numVariables = 10
  const numClauses = 20
  const problem = randomKsatProblem(k, numVariables, numClauses)
  const solver = RandomWalkKsatSolver(.01)
  const solution = solve(solver, problem)
  println("$(isSuccessful(solution) ? "Successful" : "Unsuccessful") solution found for $(k)-SAT problem with n=$(numVariables), numClauses=$(numClauses)")
  println("Check: $(checkSuccess(solution.assignment))")
  println("Solution: $(solution.assignment)")
end

run()