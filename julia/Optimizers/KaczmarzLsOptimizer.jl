export KaczmarzLsOptimizer, solve
export IncrementalKaczmarzLsOptimizer

using Distributions

# Randomized Kaczmarz with importance sampling.
immutable KaczmarzLsOptimizer <: Optimizer{LeastSquaresProblem}
  stoppingCondition:: StoppingCondition{SimpleSolverState}
end

function solve(this:: KaczmarzLsOptimizer, problem:: LeastSquaresProblem)
  const m = numObjectiveComponents(problem)
  const n = numVars(problem)
  const rowNormsSquared = [norm(obj.ai, 2)^2 for obj in objectiveComponents(problem)]
  const frobeniusNormSquared = sum(rowNormsSquared)
  const rowDist = Categorical(rowNormsSquared / frobeniusNormSquared)

  println(rowDist)

  #FIXME: Might want to start at 0, but for now we're testing what happens
  # when 0 is the optimum...
  x = randn(n)
  
  #FIXME: Debugging.  Only works for overdetermined systems.
  const trueSolution = solve(NormalEquationsLsOptimizer(), problem)
  const trueResidual = objectiveValue(problem, trueSolution.assignment)
  println("True residual: $(trueResidual)")
  
  state = SimpleSolverState(0)
  
  while ! shouldStop(this.stoppingCondition, state)
    println("Residual before iteration $(state.k): $(objectiveValue(problem, RealAssignment(x)))")
    println("Distance to optimum: $(norm(x - trueSolution.assignment.vars, 2))")
    const objIdx = rand(rowDist)
    println("Picked $(objIdx)")
    const obj = objectiveComponents(problem)[objIdx]
    const rowNormSquared = rowNormsSquared[objIdx]
    const move = ((obj.bi - dot(obj.ai, x)) / rowNormSquared) * obj.ai
    x = x + move
    next!(state)
  end
  
  successfulSolution(RealAssignment(x))
end


# The old-style random Kaczmarz without importance sampling.
immutable UniformKaczmarzLsOptimizer <: Optimizer{LeastSquaresProblem} end

function solve(this:: UniformKaczmarzLsOptimizer, problem:: LeastSquaresProblem)
  const m = numObjectiveComponents(problem)
  const n = numVars(problem)

  #FIXME: Might want to start at 0, but for now we're testing what happens
  # when 0 is the optimum...
  x = randn(n)
  
  #FIXME: Debugging.  Only works for overdetermined systems.
  const trueSolution = solve(NormalEquationsLsOptimizer(), problem)
  const trueResidual = objectiveValue(problem, trueSolution.assignment)
  println("True residual: $(trueResidual)")
  
  for i = 1:1000 #FIXME: Use an actual stopping condition.
    println("Residual before iteration $(i): $(objectiveValue(problem, RealAssignment(x)))")
    println("Distance to optimum: $(norm(x - trueSolution.assignment.vars, 2))")
    const objIdx = rand(1:m)
    println("Picked $(objIdx)")
    const obj = objectiveComponents(problem)[objIdx]
    # We just project onto the affine subspace where <obj.ai, x> - bi = 0.
    # The point x_i^* = bi*obj.ai / ||obj.ai||^2 is in this set, so it is the 
    # set A_i = x_i^* + V_i, where V_i is the nullspace of obj.ai.  This 
    # projection is given by:
    # P_{A_i}(x) = x_i^* + P_{V_i}(x - x_i^*)
    # To simplify things, just observe that the negative gradient will always 
    # point toward the projection, so we just have to choose the step size k:
    # P_{A_i}(x) = x - k 2 ai (<ai, x> - bi)
    # <x - k 2 ai (<ai, x> - bi), ai> = bi
    # => <x, ai> - bi = 2 k <ai, ai> (<x, ai> - bi)
    # => k = 1/2<ai, ai>
    const move = (obj.bi - dot(obj.ai, x)) / norm(obj.ai, 2)^2 * obj.ai
    x = x + move
  end
  
  successfulSolution(RealAssignment(x))
end
