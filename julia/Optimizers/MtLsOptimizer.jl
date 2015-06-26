export MtLsOptimizer, solve

using Distributions

immutable MtLsOptimizer <: Optimizer{LeastSquaresProblem}
  stoppingCondition:: StoppingCondition{SimpleSolverState}
end

function solve(this:: MtLsOptimizer, problem:: LeastSquaresProblem)
  const A = vcat([obj.ai for obj in objectiveComponents(problem)]...)
  const b = [obj.bi for obj in objectiveComponents(problem)]
  const m = numObjectiveComponents(problem)
  const n = numVars(problem)

  #FIXME: Might want to start at 0, but for now we're testing what happens
  # when 0 is the optimum...
  x = randn(n)
  
  #FIXME: Debugging.  Only works for overdetermined systems.
  const trueSolution = solve(NormalEquationsLsOptimizer(), problem)
  const trueResidual = objectiveValue(problem, trueSolution.assignment)
  println("True residual: $(trueResidual)")
  
  # Initially the objective value for a single component is:
  #   (<ai, x> - bi)^2
  # Assuming we used Gaussian sampling to generate the problem, all of these
  # variables are iid Gaussian(0,I) for appropriate dimensions.  Odd powers
  # of anything will be 0 in expectation.  So:
  #   E (<ai, x> - bi)^2 = E (<ai, x>^2 + bi^2)
  #     = 1 + E (\sum_{j=1}^{n} (aij xj)^2)
  #     = 1 + n E (aij xj)^2
  #     = 1 + n E (aij)^2 E (xj)^2
  #     = 1 + n
  # The objective values are not independent, since they are all functions of
  # x, but individually this is their expectation.  So we will make the initial 
  # threshold 2(n+1) as a reasonable guess.
  threshold = 2*(n+1)
  
  state = SimpleSolverState(0)
  
  while ! shouldStop(this.stoppingCondition, state)
    println("Residual before iteration $(state.k): $(objectiveValue(problem, RealAssignment(x)))")
    println("Distance to optimum: $(norm(x - trueSolution.assignment.vars, 2))")
    const candidateRows = filter(obj -> apply(obj, RealAssignment(x)) > threshold, objectiveComponents(problem))
    const numCandidates = length(candidateRows)
    if numCandidates == 0
      threshold /= 2
      println("Decreasing threshold to $(threshold)")
      continue
    end
    const objIdx = rand(1:numCandidates)
    println("Picked row $(objIdx)")
    const obj = candidateRows[objIdx]
    const move = (obj.bi - dot(obj.ai, x)) / norm(obj.ai, 2)^2 * obj.ai
    x = x + move
    next!(state)
  end
  
  successfulSolution(RealAssignment(x))
end
