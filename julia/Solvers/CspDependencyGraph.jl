export DependencyGraph, nodes, edges, hasEdge, hasNode, degree, neighbors, neighborhood, maxDegree, inducedSubgraph
export MarkedGraph
export CspDependencyGraph, makeGraphWithEdgeCriterion, inducedSubgraph
export EdgeCriterion, SharedVariable, NegativeCorrelation


abstract DependencyGraph

function nodes(this:: DependencyGraph)
  raiseAbstract("nodes", this)
end

# A Set{(Int64,Int64)} of directed edges in the graph (each undirected edge (i,j)
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

# True if there is an edge e = (a,b).
function hasEdge(this:: DependencyGraph, e:: (Int64, Int64))
  e in edges(this)
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
  CspDependencySubgraph(this, intersect(nodes(this), nodeSubset))
end


immutable MarkedGraph{MarkType}
  graph:: DependencyGraph
  marks:: Dict{Int64, MarkType}
end


immutable CspDependencyGraph <: DependencyGraph
  problem:: VariableCsp
  #TODO: Could use a full IntSet for this.
  nodes:: Set{Int64}
  # Two clauses have an edge if they share a variable (its sign doesn't
  # matter).  This is a symmetric relation, so this dictionary holds edges
  # in both directions.
  edges:: Set{(Int64, Int64)}
  neighbors:: Dict{Int64, Set{Int64}}
end

function nodes(this:: CspDependencyGraph)
  this.nodes
end

# A Set{(Int64, Int64)} of directed edges in the graph (each undirected edge (i,j)
# counts as both (i,j) and (j,i)).
function edges(this:: CspDependencyGraph)
  this.edges
end

function neighbors(this:: CspDependencyGraph, node:: Int64)
  this.neighbors[node]
end

function hasNode(this:: CspDependencyGraph, node:: Int64)
  node >= 1 && node <= m(this.problem)
end

function inducedSubgraph(this:: CspDependencyGraph, nodeSubset:: Set{Int64})
  #TODO: Assert no element of @nodeSubset is bigger than the max node ID.
  CspDependencySubgraph(this, nodeSubset)
end

abstract EdgeCriterion
immutable SharedVariable <: EdgeCriterion end
immutable NegativeCorrelation <: EdgeCriterion end

function meetsCriterion(criterion:: SharedVariable, problem:: VariableCsp, clauseIdx:: Int64, otherClauseIdx:: Int64)
  const clause = constraints(problem)[clauseIdx]
  const otherClause = constraints(problem)[otherClauseIdx]
  shareVariable(clause, otherClause)
end

function meetsCriterion(criterion:: NegativeCorrelation, problem:: VariableCsp, clauseIdx:: Int64, otherClauseIdx:: Int64)
  couldBeNegativelyCorrelated(problem, clauseIdx, otherClauseIdx)
end

# Compute the edges and neighbor-sets of the dependency graph corresponding
# to @problem.
function computeEdgesAndNeighbors(problem:: VariableCsp, criterion:: EdgeCriterion)
  if problem.numVariables > numClauses(problem)
    computeEdgesAndNeighborsByNode(problem, criterion)
  else
    computeEdgesAndNeighborsByVariable(problem, criterion)
  end
end

# As computeEdgesAndNeighbors, but takes O(n m) time, where m is the number
# of clauses in @problem and n is the number of variables.
function computeEdgesAndNeighborsByVariable(problem:: VariableCsp, criterion:: EdgeCriterion)
  edges = Set{(Int64, Int64)}()
  neighbors = Dict{Int64, Set{Int64}}()
  for variable in 1:problem.numVariables
    # First identify all clauses sharing this variable.
    clausesWithVariableIndices = Set{Int64}()
    for (clauseIdx, clause) in enumerate(constraints(problem))
      if variable in vbl(clause) #TODO: Takes O(k) time.
        push!(clausesWithVariableIndices, clauseIdx)
      end
    end
    # Now add edges between all the clauses sharing the variable.
    for clauseIdx in clausesWithVariableIndices
      for otherClauseIdx in clausesWithVariableIndices
        const clause = constraints(problem)[clauseIdx]
        const otherClause = constraints(problem)[otherClauseIdx]
        if clauseIdx != otherClauseIdx && meetsCriterion(criterion, problem, clause, otherClause)
          push!(get!(() -> Set{Int64}(), neighbors, clauseIdx), otherClauseIdx)
        end
      end
    end
  end
  (edges, neighbors)
end

# As computeEdgesAndNeighbors, but takes O(m^2) time, where m is the number
# of clauses in @problem.
function computeEdgesAndNeighborsByNode(problem:: VariableCsp, criterion:: EdgeCriterion)
  edges = Set{(Int64, Int64)}()
  neighbors = Dict{Int64, Set{Int64}}()
  for (clauseIdx, clause) in enumerate(constraints(problem))
    for (otherClauseIdx, otherClause) in enumerate(constraints(problem))
      if clauseIdx != otherClauseIdx && meetsCriterion(criterion, problem, clause, otherClause)
        push!(edges, (clauseIdx, otherClauseIdx))
        push!(get!(() -> Set{Int64}(), neighbors, clauseIdx), otherClauseIdx)
      end
    end
  end
  (edges, neighbors)
end

# Make a dependency graph for @problem.  Two clauses are dependent if they
# share a variable AND if they meet @criterion, which may additionally sharpen
# the requirement.
function makeGraphWithEdgeCriterion(problem:: VariableCsp, criterion:: EdgeCriterion)
  nodes = Set(1:numClauses(problem))
  #println("Building graph...")
  edgesAndNeighbors = computeEdgesAndNeighbors(problem, criterion)
  #println("Done building graph.")
  edges = edgesAndNeighbors[1]
  neighbors = edgesAndNeighbors[2]
  CspDependencyGraph(problem, nodes, edges, neighbors)
end

immutable CspDependencySubgraph <: DependencyGraph
  originalGraph:: DependencyGraph
  nodeSubset:: Set{Int64}
end

function nodes(this:: CspDependencySubgraph)
  this.nodeSubset
end

function edges(this:: CspDependencySubgraph)
  filter(e -> hasNode(this, e[1]) && hasNode(this, e[2]), edges(this.originalGraph))
end

function hasEdge(this:: CspDependencySubgraph, a:: Int64, b:: Int64)
  a in this.nodeSubset && b in this.nodeSubset && hasEdge(originalGraph, a, b)
end

function neighbors(this:: CspDependencySubgraph, node:: Int64)
  intersect(this.nodeSubset, neighbors(this.originalGraph, node))
end