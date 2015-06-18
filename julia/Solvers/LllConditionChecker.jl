export checkSimpleLllCondition, checkStandardLllCondition

function checkSimpleLllCondition(problem:: ProductMeasureCsp)
  checkSimpleLllCondition(problem, makeGraphWithCriterion(problem, SharedVariable))
end

function checkSimpleLllCondition(problem:: ProductMeasureCsp, dependencyGraph:: DependencyGraph)
  const p = maximum(map(i -> constraintProb(problem, i), 1:m(problem)))
  const d = maxDegree(dependencyGraph)
  e*p*(d+1) < 1
end

function checkStandardLllCondition(problem:: ProductMeasureCsp)
  checkStandardLllCondition(problem, makeGraphWithCriterion(problem, SharedVariable))
end

function checkLopsidedLllCondition(problem:: ProductMeasureCsp)
  checkStandardLllCondition(problem, makeGraphWithCriterion(problem, NegativeCorrelation))
end

function checkStandardLllCondition(problem:: ProductMeasureCsp, dependencyGraph:: DependencyGraph)
  #FIXME
end