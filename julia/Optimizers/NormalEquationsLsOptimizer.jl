export NormalEquationsLsOptimizer, solve

using Distributions

immutable NormalEquationsLsOptimizer <: Optimizer{LeastSquaresProblem} end

function solve(this:: NormalEquationsLsOptimizer, problem:: LeastSquaresProblem)
  const m = numObjectiveComponents(problem)
  const n = numVars(problem)
  const At = reshape(vcat([o.ai for o in objectiveComponents(problem)]...), n, m)
  const b = [o.bi for o in objectiveComponents(problem)]
  const solution = inv(At * At') * At * b
  successfulSolution(RealAssignment(solution))
end