using ArgParse
using Utils, GeneratedData, Problems, Solvers

function compareGroundTruth(problem:: KsatProblem)
  #println("Using exhaustive search to find a solution.")
  const exhaustiveSolver = ExhaustiveKsatSolver()
  const trueSolution:: AnnotatedKsatSolution = solve(exhaustiveSolver, problem)
  if (isSuccessful(trueSolution))
    #println("The problem has a solution: $(string(trueSolution))")
    #println("$(trueSolution.numSatisfyingSolutions)/$(trueSolution.numPotentialSolutions) ($(trueSolution.numSatisfyingSolutions/trueSolution.numPotentialSolutions)) satisfying solutions.")
    #println ("$(trueSolution.numSatisfyingSolutions/trueSolution.numPotentialSolutions)")

    const probability = trueSolution.numSatisfyingSolutions/trueSolution.numPotentialSolutions
  else
    #println("0")
    const probability = 0
  end
  return probability
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
    "--seed", "-e"
      help = "the random seed" #FIXME
      arg_type = Int
  end

  return parse_args(s)
end

function run()
  # @foo()
  const args = parseArgs()
  const problemGenerator = eval(parse(args["data-generator"]))
  const solver = eval(parse(args["solver"]))

  x = Float64[]
  const times = 1

  sum_maxDegree = Int64[]
  #sum_avgDegree = Float64[]

  for i=1:times
    const problem = generate(problemGenerator)

    const graph = makeKsatDependencyGraph(problem)
    push!(sum_maxDegree,graph.maxDegree)
    #push!(sum_avgDegree,graph.totalDegree/length(graph.nodes))

    if args["compare-ground-truth"]
      push!(x,compareGroundTruth(problem))
    end

  end

  sort!(sum_maxDegree)
  #sort!(sum_avgDegree)
  sort!(x)

  println("$(string(sum_maxDegree[1]))\t$(string(sum_maxDegree[2]))\t$(string(sum_maxDegree[5]))\t$(string(sum_maxDegree[9]))\t$(string(sum_maxDegree[10]))")

  #println("$(string(sum_avgDegree[1]))\t$(string(sum_avgDegree[2]))\t$(string(sum_avgDegree[5]))\t$(string(sum_avgDegree[9]))\t$(string(sum_avgDegree[10]))")

  println("$(string(x[1]))\t$(string(x[1]))\t$(string(x[1]))\t$(string(x[1]))\t$(string(x[1]))")

  println("$(string(problem))")

  #const solution = solve(solver, problem)
  #println("$(isSuccessful(solution) ? "Successful" : "Unsuccessful") solution #found for $(problem.k)-SAT problem with n=$(problem.numVariables), numClauses=$(length(problem.clauses))")
  #println("Check: $(checkSuccess(solution.assignment, problem))")
  #println("Solution: $(solution.assignment)")
end

run()
