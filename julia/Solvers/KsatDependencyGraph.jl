export KsatDependencyGraph, makeKsatDependencyGraph, hasEdge

immutable KsatDependencyGraph
  problem:: KsatProblem
  # Two clauses have an edge if they share a variable (its sign doesn't
  # matter).  This is a symmetric relation, so this dictionary holds edges
  # in both directions.
  edges:: Set{(Int64, Int64)}
  maxDegree:: Int64
  totalDegree:: Int64
end

function makeKsatDependencyGraph(problem:: KsatProblem)
  edges = Set{(Int64, Int64)}()
  maxDegree = 0
  totalDegree = 0
  for (clauseIdx, clause) in enumerate(problem.clauses)
    numEdges = 0
    for (otherClauseIdx, otherClause) in enumerate(problem.clauses)
      if hasEdge(clause, otherClause)
        push!(edges, clauseIdx, otherClauseIdx)
        numEdges++
      end
    end
    maxDegree = max(maxDegree, numEdges)
    totalDegree += numEdges
  end
  KsatDependencyGraph(problem, edges, maxDegree, totalDegree)
end

function hasEdge(clauseA:: SatClause, clauseB:: SatClause)
  if length(clauseA.variables) < 50
    for varA in clauseA.variables
      for varB in clauseB.variables
        if varA == varB
          return true
        end
      end
    end
    false
  else
    # Use a linear-time algorithm with higher overhead when k is large.
    const varsA = Set(clauseA.variables)
    const varsB = Set(clauseB.variables)
    !isempty(intersect(varsA, varsB))
  end
end