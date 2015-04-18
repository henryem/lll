export Problem, Solution, isSuccessful

abstract Problem

abstract Solution

function isSuccessful(this:: Solution)
  raiseAbstract("isSuccessful", this)
end
