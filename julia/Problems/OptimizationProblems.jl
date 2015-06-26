export OptimizationProblem, objectiveValue
export RealConstraint
export SimpleL2Constraint, isSatisfied
export ObjectiveFunction, apply
export SimpleObjectiveFunction, minimumValue, sampleSublevelSet
export SummedObjectiveProblem, objectiveComponents, numObjectiveComponents
export LeastSquaresObjectiveFunction
export LeastSquaresProblem


using Utils

# A CSP with an objective that is to be minimized given the constraints of the
# CSP.
abstract OptimizationProblem{V <: VariableType, A <: VariableAssignment, C <: VariableConstraint} <: VariableCsp{V, A, C}

function objectiveValue{V <: VariableType, A <: VariableAssignment, C <: VariableConstraint}(this:: OptimizationProblem{V, A, C}, a:: A)
  raiseAbstract("objectiveValue", this)
end


typealias RealConstraint VariableConstraint{RealAssignment, Real}


immutable NoConstraint <: RealConstraint end

immutable SimpleL2Constraint <: RealConstraint
  ballSize:: Float64
end

function isSatisfied(this:: SimpleL2Constraint, a:: RealAssignment)
  norm(a.vars, 2) <= this.ballSize
end


abstract ObjectiveFunction{A <: Assignment}

function apply{A <: Assignment}(this:: ObjectiveFunction{A}, a:: A)
  raiseAbstract("apply", this)
end


# An objective function with simple analytic properties.  In particular, there
# must be a fast oracle for computing the minimum value over an l2 ball, and 
# there must be a fast oracle for sampling (see sampleSublevelSet).
abstract SimpleObjectiveFunction{A <: Assignment}

function minimumValue(this:: SimpleObjectiveFunction, compactConstraint:: SimpleL2Constraint)
  raiseAbstract("minimumValue", this)
end

# Sample from the Lebesgue measure on the intersection of @compactConstraint's
# feasible set and the sublevel set of @this with function value at most
# @maxValue.
function sampleSublevelSet(this:: SimpleObjectiveFunction{RealAssignment}, maxValue:: Float64, compactConstraint:: SimpleL2Constraint)
  raiseAbstract("sampleSublevelSet", this)
end


# An optimization problem with an objective that is a sum of simple functions.
abstract SummedObjectiveProblem{V <: VariableType, A <: VariableAssignment, C <: VariableConstraint} <: OptimizationProblem{V, A, C}

function objectiveComponents(this:: SummedObjectiveProblem)
  raiseAbstract("objectiveComponents", this)
end

function numObjectiveComponents(this:: SummedObjectiveProblem)
  length(objectiveComponents(this))
end

function objectiveValue{V <: VariableType, A <: VariableAssignment, C <: VariableConstraint}(this:: SummedObjectiveProblem{V, A, C}, a:: A)
  mapreduce(o -> apply(o, a), +, objectiveComponents(this))
end


immutable LeastSquaresObjectiveFunction <: SimpleObjectiveFunction{RealAssignment}
  ai:: Vector{Float64}
  bi:: Float64
end

function apply(this:: LeastSquaresObjectiveFunction, x:: RealAssignment)
  (dot(this.ai, x.vars) - this.bi)^2
end

function minimumValue(this:: LeastSquaresObjectiveFunction, compactConstraint:: SimpleL2Constraint)
  0
end


immutable LeastSquaresProblem <: SummedObjectiveProblem{Real, RealAssignment, NoConstraint}
  n:: Int64
  objectives:: Vector{LeastSquaresObjectiveFunction}
end

function objectiveComponents(this:: LeastSquaresProblem)
  this.objectives
end

function constraints(this:: LeastSquaresProblem)
  return []
end

function numVars(this:: LeastSquaresProblem)
  return this.n
end


#FIXME
# x |-> log(1 + exp(-bi <ai, x>))
# immutable LogisticObjectiveFunction <: SimpleObjectiveFunction{RealAssignment}
#   ai:: Vector{Float64}
#   bi:: Float64
# end
#
# function minimumValue(this:: SimpleObjectiveFunction)
#
# # A logistic regression problem with Ivanov (hard l2-ball constraint)
# # regularization.
# immutable LogisticRegressionProblem <: SummedObjectiveProblem{RealAssignment}
#   objectives:: Vector{SimpleObjectiveFunction}
#
#   ballSize:: Float64
#   A:: Matrix{Float64}
#   b:: Vector{Float64}
#
# end