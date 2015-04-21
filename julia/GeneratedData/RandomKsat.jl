export RandomKsatGenerator, generate

using Distributions
using Problems

immutable RandomKsatGenerator <: DataGenerator
  k:: Int64
  numVariables:: Int64
  numClauses:: Int64
end

function generate(this:: RandomKsatGenerator)
  const clauses = map(1:this.numClauses) do clauseIdx
    const variables = sample(1:this.numVariables, this.k, replace=false)
    const signs = randbool(this.k)
    SatClause(variables, signs)
  end
  KsatProblem(this.k, this.numVariables, clauses)
end
