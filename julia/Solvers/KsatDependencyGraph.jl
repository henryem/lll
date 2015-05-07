export DependencyGraph, nodes, edges, hasEdge, hasNode, degree, neighbors, neighborhood, maxDegree, MarkedGraph, KsatDependencyGraph, makeKsatDependencyGraph, inducedSubgraph

abstract DependencyGraph

function nodes(this:: DependencyGraph)
  raiseAbstract("nodes", this)
end

# A Set{Int64} of directed edges in the graph (each undirected edge (i,j)
# counts as both (i,j) and (j,i)).
function edges(this:: DependencyGraph)
  raiseAbstract("edges", this)
end

function neighbors(this:: DependencyGraph, node:: Int64)
  raiseAbstract("neighbors", this)
end

function neighborhood(this:: DependencyGraph, nodes:: Set{Int64})
  union(nodes, map(node -> neighbors(this, node), nodes)...)
end

# True if there is an edge between @a and @b.
function hasEdge(this:: DependencyGraph, a:: Int64, b:: Int64)
  (a, b) in edges(this)
end

# True if this graph contains a node with ID @node.
function hasNode(this:: DependencyGraph, node:: Int64)
  node in nodes(this)
end

# The degree of @node.
function degree(this:: DependencyGraph, node:: Int64)
  length(neighbors(this, node))
end

function maxDegree(this:: DependencyGraph)
  maxDeg = 0
  for node in nodes(this)
    maxDeg = max(maxDeg, degree(this, node))
  end
  maxDeg
end

function totalDegree(this:: DependencyGraph)
  length(edges(this))
end

function inducedSubgraph(this:: DependencyGraph, nodeSubset:: Set{Int64})
  KsatDependencySubgraph(this, intersect(nodes(this), nodeSubset))
end


immutable MarkedGraph{MarkType}
  graph:: DependencyGraph
  marks:: Dict{Int64, MarkType}
end


immutable KsatDependencyGraph <: DependencyGraph
  problem:: KsatProblem
  #TODO: Could use a full IntSet for this.
  nodes:: Set{Int64}
  # Two clauses have an edge if they share a variable (its sign doesn't
  # matter).  This is a symmetric relation, so this dictionary holds edges
  # in both directions.
  edges:: Set{(Int64, Int64)}
  neighbors:: Dict{Int64, Set{Int64}}
end

function nodes(this:: DependencyGraph)
  this.nodes
end

# A Set{(Int64, Int64)} of directed edges in the graph (each undirected edge (i,j)
# counts as both (i,j) and (j,i)).
function edges(this:: KsatDependencyGraph)
  this.edges
end

function neighbors(this:: KsatDependencyGraph, node:: Int64)
  this.neighbors[node]
end

function hasNode(this:: KsatDependencyGraph, node:: Int64)
  node >= 1 && node <= numClauses(this.problem)
end

function inducedSubgraph(this:: KsatDependencyGraph, nodeSubset:: Set{Int64})
  #TODO: Assert no element of @nodeSubset is bigger than the max node ID.
  KsatDependencySubgraph(this, nodeSubset)
end

# Compute the edges and neighbor-sets of the dependency graph corresponding
# to @problem.
function computeEdgesAndNeighbors(problem:: KsatProblem)
  if problem.numVariables > numClauses(problem)
    computeEdgesAndNeighborsByNode(problem)
  else
    computeEdgesAndNeighborsByVariable(problem)
  end
end

# As computeEdgesAndNeighbors, but takes O(n m) time, where m is the number
# of clauses in @problem and n is the number of variables.
function computeEdgesAndNeighborsByVariable(problem:: KsatProblem)
  edges = Set{(Int64, Int64)}()
  neighbors = Dict{Int64, Set{Int64}}()
  for variable in 1:problem.numVariables
    # First identify all clauses sharing this variable.
    clausesWithVariableIndices = Set{Int64}()
    for (clauseIdx, clause) in enumerate(problem.clauses)
      if variable in clause.variables #TODO: Takes O(k) time.
        push!(clausesWithVariableIndices, clauseIdx)
      end
    end
    # Now add edges between all the clauses sharing the variable.
    for clauseIdx in clausesWithVariableIndices
      for otherClauseIdx in clausesWithVariableIndices
        if clauseIdx != otherClauseIdx
          push!(edges, (clauseIdx, otherClauseIdx))
          push!(get!(() -> Set{Int64}(), neighbors, clauseIdx), otherClauseIdx)
        end
      end
    end
  end
  (edges, neighbors)
end

# As computeEdgesAndNeighbors, but takes O(m^2) time, where m is the number
# of clauses in @problem.
function computeEdgesAndNeighborsByNode(problem:: KsatProblem)
  edges = Set{(Int64, Int64)}()
  neighbors = Dict{Int64, Set{Int64}}()
  for (clauseIdx, clause) in enumerate(problem.clauses)
    for (otherClauseIdx, otherClause) in enumerate(problem.clauses)
      if clauseIdx != otherClauseIdx && checkForEdge(clause, otherClause)
        push!(edges, (clauseIdx, otherClauseIdx))
        push!(get!(() -> Set{Int64}(), neighbors, clauseIdx), otherClauseIdx)
      end
    end
  end
  (edges, neighbors)
end

function makeKsatDependencyGraph(problem:: KsatProblem)
  nodes = Set(1:numClauses(problem))
  #println("Building graph...")
  edgesAndNeighbors = computeEdgesAndNeighbors(problem)
  #println("Done building graph.")
  edges = edgesAndNeighbors[1]
  neighbors = edgesAndNeighbors[2]
  KsatDependencyGraph(problem, nodes, edges, neighbors)
end

function checkForEdge(clauseA:: SatClause, clauseB:: SatClause)
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


immutable KsatDependencySubgraph <: DependencyGraph
  originalGraph:: DependencyGraph
  nodeSubset:: Set{Int64}
end

function nodes(this:: KsatDependencySubgraph)
  this.nodeSubset
end

function edges(this:: KsatDependencySubgraph)
  filter(e -> hasNode(this, e[1]) && hasNode(this, e[2]), edges(this.originalGraph))
end

function hasEdge(this:: KsatDependencySubgraph, a:: Int64, b:: Int64)
  a in this.nodeSubset && b in this.nodeSubset && hasEdge(originalGraph, a, b)
end

function neighbors(this:: KsatDependencySubgraph, node:: Int64)
  intersect(this.nodeSubset, neighbors(this.originalGraph, node))
end