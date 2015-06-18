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

# See http://arxiv.org/pdf/cs/0309020.pdf
SMALL_K_THRESHOLDS = [4.267, 9.931, 21.117, 43.37, 87.79]
MAX_SMALL_K = 7
function makeHardGenerator(k:: Int64, numVariables:: Int64)
  const numClauses = if k <= MAX_SMALL_K
    SMALL_K_THRESHOLDS[k-2]
  else
    # See https://users.soe.ucsc.edu/~optas/papers/ksat-ams.pdf
    #FIXME
  end
  RandomKsatGenerator(k, numVariables, numClauses)
end