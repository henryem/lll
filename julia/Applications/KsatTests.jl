using ArgParse
using Utils, GeneratedData, Problems, Solvers

function compareGroundTruth(problem:: KsatProblem)
  println("Using exhaustive search to find a solution.")
  const exhaustiveSolver = ExhaustiveKsatSolver()
  const trueSolution:: AnnotatedKsatSolution = solve(exhaustiveSolver, problem)
  if (isSuccessful(trueSolution))
    println("The problem has a solution: $(string(trueSolution))")
    println("$(trueSolution.numSatisfyingSolutions)/$(trueSolution.numPotentialSolutions) ($(trueSolution.numSatisfyingSolutions/trueSolution.numPotentialSolutions)) satisfying solutions.")
  else
    println("The problem has no solution.")
  end
end

function parseArgs()
  s = ArgParseSettings()
  
  @add_arg_table s begin
    "--solver", "-s"
      help = "the Solver to use, a Julia string"
    "--data-generator", "-d"
      help = "the DataGenerator to use, a Julia string"
    "--compare-ground-truth", "-g"
      help = "whether to solve exhaustively to compare with ground truth"
      action = :store_true
    "--problem-seed", "-e"
      help = "the random seed for generating the problem"
      arg_type = Int
    "--solver-seed", "-l"
      help = "the random seed for solving the problem"
      arg_type = Int
  end

  return parse_args(s)
end

function run()
  const args = parseArgs()
  srand(args["problem-seed"])
  const problemGenerator = eval(parse(args["data-generator"]))
  const problem = generate(problemGenerator)
  srand(args["solver-seed"])
  const solver = eval(parse(args["solver"]))
  if args["compare-ground-truth"]
    compareGroundTruth(problem)
  end
  const solution = solve(solver, problem)
  #println("$(isSuccessful(solution) ? "Successful" : "Unsuccessful") solution found for $(problem.k)-SAT problem with n=$(problem.numVariables), numClauses=$(length(problem.clauses))")
  #println("Check: $(checkSuccess(solution.assignment, problem))")
  #println("Solution: $(solution.assignment)")
end

run()
