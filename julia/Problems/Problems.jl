export Assignment
export Problem
export Constraint, isSatisfied
export Csp, m, constraints
export VariableType, Binary, Discrete, Real, NonnegativeReal
export VariableAssignment
export VariableConstraint, vbl, k
export VariableCsp, numVars, variables
export ProductMeasureCsp, jointSample, marginalSample!, constraintProb
export ProblemSolution, isSuccessful
export Solution, successfulSolution, unsuccessfulSolution

using Utils

# A member of the domain of a problem.  For example, a vector of 5 real
# numbers.  Not necessarily a feasible or optimal solution.  For performance
# reasons, instances should be mutable.
abstract Assignment

#FIXME: Probably unnecessary.
# Some kind of zero or default element of the domain of a problem.  Examples:
# an assignment of all zeros; the trivial permutation.
function defaultAssignment{A <: Assignment}(:: Type{A})
  raiseAbstract("defaultAssignment", A)
end


abstract Problem{A <: Assignment}


abstract Constraint{A <: Assignment}

function isSatisfied{A <: Assignment}(this:: Constraint{A}, assignment:: A)
  raiseAbstract("isSatisfied", this)
end


# A problem in which we want to find an element of some domain that satisfies
# m separate constraints.  m is finite, and it is assumed that the constraints
# (whatever their internal semantics) are indexed by integers from 1 to m.
# C <: Constraint{A}
abstract Csp{C <: Constraint, A <: Assignment} <: Problem{A}

function m(this:: Csp)
  length(constraints(this))
end

#FIXME: numClauses() is deprecated.
function numClauses(this:: Csp)
  m(this)
end

function constraints(this:: Csp)
  raiseAbstract("constraints", this)
end

#FIXME: Why doesn't the compiler like this?
# C <: Constraint{A}
function isSatisfied{C <: Constraint, A <: Assignment}(this:: Csp{C, A}, assignment:: A)
  for c in constraints(this)
    if !isSatisfied(c, assignment)
      return false
    end
  end
  return true
end

const MAX_DISPLAYED_CONSTRAINTS = 100
function Base.string(this:: Csp)
  const numDisplayedConstraints = min(MAX_DISPLAYED_CONSTRAINTS, m(this))
  const constraintsString = join(map(c -> "($(string(c)))", constraints(this)[1:numDisplayedConstraints]), "&")
  "CSP $(constraintsString)$(numDisplayedConstraints < m(this) ? "..." : "")"
end


abstract VariableType{UnderlyingType}

immutable Binary <: VariableType{Bool} end
immutable Discrete <: VariableType{Int64}
  d:: Int64
end
immutable Real <: VariableType{Float64} end
immutable NonnegativeReal <: VariableType{Float64} end


abstract VariableAssignment{V <: VariableType} <: Assignment

# Some kind of zero or default element of the domain of a problem.  Examples:
# an assignment of all zeros; the trivial permutation.
function defaultAssignment{A <: Assignment}(numVariables:: Int64, :: Type{A})
  raiseAbstract("defaultAssignment", A)
end

function defaultAssignment{A <: VariableAssignment}(:: Type{A})
  defaultAssignment(0, A)
end

# A constraint that depends (in the functional sense) on only a subset of the
# variables of a variable CSP.
# A <: VariableAssignment{V}
abstract VariableConstraint{A <: VariableAssignment, V <: VariableType} <: Constraint{A}

# The indices of variables on which @this depends.  (The notation is from
# Moser and Tardos.)
function vbl(this:: VariableConstraint)
  raiseAbstract("vbl", this)
end

#FIXME: What was this before?  Need to replace old calls.
# The number of variables on which @this depends.  Equals length(vlb(this)).
function k(this:: VariableConstraint)
  length(vbl(this))
end


# A CSP in which the problem domain is a product of n variables of the same
# type.  For example, {0,1}^n, R^n, or [d]^n.  n is finite, and it is assumed
# that the variables (whatever their internal semantics) are indexed by 
# integers from 1 to n.
# Note that products of heterogeneous types (for example, 2 real variables and 
# 3 binary variables) are not supported.  This is a weakness of this type 
# hierarchy, but we hope that the clarity provided by static typing is worth
# the restriction.  Supporting heterogeneous types would entail adding a new
# subclass of Csp.  (A similar thing is true of supporting heterogeneous
# constraint types, e.g. mixed linear and integer constraints.)
# A <: VariableAssignment{V}
# C <: VariableConstraint{A, V}
abstract VariableCsp{V <: VariableType, A <: VariableAssignment, C <: VariableConstraint} <: Csp{C, A}

function numVars(this:: VariableCsp)
  raiseAbstract("numVars", this)
end


# A variable CSP equipped with a product measure on the variables.
# A <: VariableAssignment{V}
# C <: VariableConstraint{A, V}
abstract ProductMeasureCsp{V <: VariableType, A <: VariableAssignment, C <: VariableConstraint} <: VariableCsp{V, A, C}

# A <: VariableAssignment{V}
# C <: VariableConstraint{A, V}
function jointSample{V <: VariableType, A <: VariableAssignment, C <: VariableConstraint}(this:: ProductMeasureCsp{V, A, C})
  assignment = defaultAssignment(numVars(this), A)
  marginalSample!(this, 1:numVars(this), assignment)
  assignment
end

# Sample from the measure on the problem domain.  The measure is marginalized
# down to the variables in @vbls.  The sampled variable values are placed in
# @assignment.
# A <: VariableAssignment{V}
# C <: VariableConstraint{A, V}
function marginalSample!{V <: VariableType, A <: VariableAssignment, C <: VariableConstraint}(this:: ProductMeasureCsp{V, A, C}, vbls:: AbstractVector{Int64}, assignment:: A)
  raiseAbstract("marginalSample!", this)
end

# The marginal probability that constraint @constraintIdx is satisfied under
# the measure on the variables of @this.
function constraintProb(this:: ProductMeasureCsp, constraintIdx:: Int64)
  raiseAbstract("constraintProb", this)
end

# True if constraints indexed by @constraintA and @constraintB could be
# negatively correlated under sampling from the underlying measure.  This is
# a stronger statement than that they share a variable.  For example, in a
# k-SAT problem, clauses (a|!b) and (a|d) share a variable but they are
# positively correlated.  The ``lopsided'' LLL uses this stronger condition
# to generate a dependency graph.
# This implementation assumes nothing about the problem and is conservative.
# Subclasses should override this if there is an easier or tighter way to
# check for negative correlation than is implemented here.
function couldBeNegativelyCorrelated(this:: ProductMeasureCsp, constraintA:: Int64, constraintB:: Int64)
  # By default we use the variable-overlap condition.
  bVbls = vbl(constraints(this))
  any(map(v -> v in bVbls, vbl(constraints(this)[constraintB])))
end


abstract ProblemSolution

function isSuccessful(this:: ProblemSolution)
  raiseAbstract("isSuccessful", this)
end


immutable Solution{A <: Assignment} <: ProblemSolution
  assignment:: A
  isSuccessful:: Bool
end

function isSuccessful(this:: Solution)
  this.isSuccessful
end

function successfulSolution{A <: Assignment}(assignment:: A)
  Solution(assignment, true)
end

function unsuccessfulSolution{A <: Assignment}(:: Type{A})
  Solution(defaultAssignment(A), false)
end