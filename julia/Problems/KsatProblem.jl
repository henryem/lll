export KsatProblem, k, constraints, numVars, marginalSample!, constraintProb
export SatToKsatStrategy, SatToPaddedKsatStrategy, satToKsat
export KsatSolution, isSuccessful, unsuccessfulKsatSolution

#FIXME: Mostly copied from SatProblem.  Since Julia does not have inheritance
# for concrete types, it's not straightforward to fix that.
# A conjunction of disjunctive clauses (an AND of numVariables clauses, each
# clause being an OR of k variables).  Each clause is of length exactly k.
immutable KsatProblem <: ProductMeasureCsp{Binary, BinaryAssignment, SatClause}
  k:: Int64
  numVariables:: Int64
  clauses:: AbstractVector{SatClause}
end

function k(this:: KsatProblem)
  this.k
end

function constraints(this:: KsatProblem)
  this.clauses
end

function numVars(this:: KsatProblem)
  this.numVariables
end

function marginalSample!(this:: KsatProblem, vbls:: AbstractVector{Int64}, assignment:: BinaryAssignment)
  const newValues = randbool(length(vbls))
  for (i, variableIdx) in enumerate(vbls)
    assignment.vars[variableIdx] = newValues[i]
  end
end

# The marginal probability that constraint @constraintIdx is satisfied under
# the measure on the variables of @this.
function constraintProb(this:: KsatProblem, constraintIdx:: Int64)
  2^(-k(this))
end


abstract SatToKsatStrategy

function satToKsat(this:: SatProblem, strategy:: SatToKsatStrategy)
  raiseAbstract("satToKsat", this)
end


# This strategy converts SAT instances to k-SAT instances by padding clauses
# with variables that are later constrained to be false.  The resulting k-SAT
# instance has k equal to the maximum clause length in the original problem,
# and it uses an additional 2^k-1 clauses to constrain the dummy variables to
# be false.
immutable SatToPaddedKsatStrategy <: SatToKsatStrategy end

function satToKsat(this:: SatProblem, strategy:: SatToPaddedKsatStrategy)
  const maxK = maximum(map(k, constraints(this)))
  const numDummyVariables = maxK
  println("Padding SAT problem with $(numDummyVariables) dummy variables and $(2^numDummyVariables-1) clauses to form a $(maxK)-SAT problem.")
  const dummyVariableStartIdx = numVars(this)+1
  const paddedClauses = map(constraints(this)) do clause
    const paddingSize = maxK - k(clause)
    const paddedVars = vcat(vbl(clause), dummyVariableStartIdx:(dummyVariableStartIdx+paddingSize-1))
    const paddedSigns = vcat(clause.signs, ones(Int64, paddingSize))
    SatClause(paddedVars, paddedSigns)
  end
  # We add all of the 2^k possible constraints on the k dummy variables, except
  # the constraint that one of them is true.  So the only valid solution has
  # them all false.
  const dummyVariables = dummyVariableStartIdx:(dummyVariableStartIdx+numDummyVariables-1)
  const dummyConstraints = map(0:(2^numDummyVariables-2)) do dummyConstraintIdx
    const signs = map(i -> (dummyConstraintIdx >> (i-1)) & 0x1, 1:numDummyVariables)
    SatClause(dummyVariables, signs)
  end
  const allClauses = vcat(paddedClauses, dummyConstraints)
  KsatProblem(maxK, numVars(this) + numDummyVariables, allClauses)
end
