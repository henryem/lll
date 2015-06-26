export SgdLsOptimizer, solve

using Distributions

immutable SgdLsOptimizer <: Optimizer{LeastSquaresProblem} end

function solve(this:: SgdLsOptimizer, problem:: LeastSquaresProblem)
  const m = numObjectiveComponents(problem)
  const n = numVars(problem)
  
  #FIXME: Might want to start at 0, but for now we're testing what happens
  # when 0 is the optimum...
  x = randn(n)
  
  #FIXME: Debugging.  Only works for overdetermined systems.
  const trueSolution = solve(NormalEquationsLsOptimizer(), problem)
  const trueResidual = objectiveValue(problem, trueSolution.assignment)
  println("True residual: $(trueResidual)")
  
  # The Lipschitz constant L of the problem is the spectral norm of the matrix
  # A.  This is concentrated around 2*sqrt(n).  Using 2/(nL) ensures that SGD
  # converges.  But actually we are using a weirder version of the problem
  # where there is no 1/2 in the objective, so everything is multipled by
  # 2.
  alpha = 1/(n*2*sqrt(n))
  
  for i = 1:1000 #FIXME: Use an actual stopping condition.
    println("Residual before iteration $(i): $(objectiveValue(problem, RealAssignment(x)))")
    println("Distance to optimum: $(norm(x - trueSolution.assignment.vars, 2))")
    const objIdx = rand(1:m)
    # println("Picked $(objIdx)")
    const obj = objectiveComponents(problem)[objIdx]
    const gradientEstimate = 2*(dot(obj.ai, x) - obj.bi) * obj.ai
    x = x - alpha*gradientEstimate
  end
  
  println("Final residual: $(objectiveValue(problem, RealAssignment(x)))")
  
  successfulSolution(RealAssignment(x))
end