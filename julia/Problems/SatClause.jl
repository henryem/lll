export SatClause, vbl, isSatisfied, shareVariable, haveNegativeDependency

# A disjunction of variables (for example, "A or B or (not D) or G").
immutable SatClause <: VariableConstraint{BinaryAssignment, Binary}
  variables:: Vector{Int64}
  signs:: BitArray
  
  function SatClause(variables:: Vector{Int64}, signs:: BitVector)
    assert(length(variables) == length(signs))
    new(variables, signs)
  end
end

function SatClause(variables:: AbstractVector{Int64}, signs:: AbstractVector{Bool})
  SatClause([variables], bitpack(signs))
end

function SatClause(variables:: AbstractVector{Int64}, signs:: AbstractVector{Int64})
  SatClause([variables], bitpack(signs))
end

function vbl(this:: SatClause)
  this.variables
end

function isSatisfied(this:: SatClause, assignment:: BinaryAssignment)
  # A clause is disjunctive -- an OR of variables.
  for (variableIdx, variable) in enumerate(this.variables)
    const value = assignment.vars[variable]
    if this.signs[variableIdx] == value
      return true
    end
  end
  return false
end

function Base.string(this:: SatClause)
  join(
    map(1:length(this.variables)) do varIdx
      const prefix = this.signs[varIdx] ? "" : "!"
      "$(prefix)$(this.variables[varIdx])"
    end,
    "|")
end

function shareVariable(clauseA:: SatClause, clauseB:: SatClause)
  if length(vbl(clauseA)) < 50
    for varA in vbl(clauseA)
      for varB in vbl(clauseB)
        if varA == varB
          return true
        end
      end
    end
    false
  else
    # Use a linear-time algorithm with higher overhead when k is large.
    #TODO: Should probably store Set(vbl(clause)) in the clauses anyway.
    const varsA = Set(vbl(clauseA))
    const varsB = Set(vbl(clauseB))
    !isempty(intersect(varsA, varsB))
  end
end

# True if A and B overlap on a variable where A's copy and B's copy have 
# opposite signs.
function haveNegativeDependency(clauseA:: SatClause, clauseB:: SatClause)
  if length(vbl(clauseA)) < 50
    for (signA, varA) in zip(clauseA.signs, clauseA.variables)
      for (signB, varB) in zip(clauseB.signs, clauseB.variables)
        if varA == varB && signA != signB
          return true
        end
      end
    end
    false
  else
    # A linear-time algorithm when there are many variables.
    const varsA = Set(zip(clauseA.signs, clauseA.variables))
    flippedBSigns = deepcopy(clauseB.signs)
    flipbits!(flippedBSigns)
    const varsB = Set(zip(flippedBSigns, clauseB.variables))
    # We want to check whether A and B overlap on a variable where A's copy
    # and B's copy have opposite signs.
    !isempty(intersect(varsA, varsB))
  end
end