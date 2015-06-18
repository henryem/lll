export SatLikeProblem
export SatProblem, constraints, numVars, marginalSample, constraintProb
export SatSolution, isSuccessful, unsuccessfulSatSolution

typealias SatLikeProblem ProductMeasureCsp{Binary, BinaryAssignment, SatClause}

# A conjunction of disjunctive clauses (an AND of numVariables clauses, each
# clause being an OR of variables).
immutable SatProblem <: SatLikeProblem
  numVariables:: Int64
  clauses:: AbstractVector{SatClause}
end

function constraints(this:: SatProblem)
  this.clauses
end

function numVars(this:: SatProblem)
  this.numVariables
end

function marginalSample!(this:: SatProblem, vbls:: AbstractVector{Int64}, assignment:: BinaryAssignment)
  const newValues = randbool(length(vbls))
  for (i, variableIdx) in enumerate(vbls)
    assignment.vars[variableIdx] = newValues[i]
  end
end

# The marginal probability that constraint @constraintIdx is satisfied under
# the measure on the variables of @this.
function constraintProb(this:: SatProblem, constraintIdx:: Int64)
  2^(-k(this.clauses[constraintIdx]))
end

function couldBeNegativelyCorrelated(this:: ProductMeasureCsp, constraintA:: Int64, constraintB:: Int64)
  haveNegativeCorrelation(constraintA, constraintB)
end