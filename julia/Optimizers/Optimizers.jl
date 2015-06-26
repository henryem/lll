export Optimizer

using Problems, Solvers

# An optimizer attempts to return a feasible point that minimizes or maximizes
# some objective as defined by a P.
abstract Optimizer{P <: OptimizationProblem} <: Solver{P}