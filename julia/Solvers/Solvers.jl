export Solver, solve, KsatSolver

abstract Solver{ProblemType <: Problem}

function solve(this:: Solver{P}, problem:: P)
  raiseAbstract("solve", this)
end

typealias KsatSolver Solver{KsatProblem}
