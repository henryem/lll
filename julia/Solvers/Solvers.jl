export Solver, solve, KsatSolver

using Problems

abstract Solver{ProblemType <: Problem}

function solve{P}(this:: Solver{P}, problem:: P)
  raiseAbstract("solve", this)
end

typealias KsatSolver Solver{KsatProblem}
