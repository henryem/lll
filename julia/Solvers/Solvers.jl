export Solver, solve

using Problems

abstract Solver{ProblemType <: Problem}

function solve{P}(this:: Solver{P}, problem:: P)
  raiseAbstract("solve", this)
end
