export randomKsatProblem

using Distributions
using Problem

function randomKsatProblem(k:: Int64, numVariables:: Int64, numClauses:: Int64)
  const clauses = map(1:numClauses) do clauseIdx
    const variables = sample(1:numVariables, k, replace=false)
    const signs = randbool(k)
    SatClause(variables, signs)
  end
  KsatProblem(k, numVariables, clauses)
end