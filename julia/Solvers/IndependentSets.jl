export maximalIndependentSet, lubyIndependentSet

# Some algorithms for finding independent sets in undirected graphs.
# Depends on KsatDependencyGraph.jl.
# 
# Some of the algorithms here could, in principle, be parallelized or 
# distributed.  Currently we have not done that, but we have marked places that
# would need to be modified to make algorithms run in parallel.

typealias NodeMarker Int64

# Luby's algorithm for finding maximal independent sets.  It is a Las Vegas
# algorithm, meaning that its running time is random, but it always returns
# a maximal independent set.
# See, for example, http://courses.csail.mit.edu/6.852/08/papers/Luby.pdf .
function maximalIndependentSet(this:: DependencyGraph)
  remainingGraph = this
  independentSet = Set{Int64}()
  while !isempty(nodes(remainingGraph))
    const newIndependentNodes = lubyIndependentSet(remainingGraph)
    #NOTE: Could be parallelized.
    union!(independentSet, newIndependentNodes)
    const coveredNodes = neighborhood(remainingGraph, newIndependentNodes)
    const remainingNodes = setdiff(nodes(remainingGraph), coveredNodes)
    remainingGraph = inducedSubgraph(remainingGraph, remainingNodes)
  end
  independentSet
end

# One iteration of Luby's algorithm for finding maximal independent sets.
# This merely finds an independent (but not necessarily maximal) set.
# See, for example, http://courses.csail.mit.edu/6.852/08/papers/Luby.pdf .
function lubyIndependentSet(this:: DependencyGraph)
  const ranks = markNodesRandomly(this)
  findLocalMinima(this, ranks)
end

# Assign a random marker of type NodeMarker to each vertex of @this.
function markNodesRandomly(this:: DependencyGraph)
  #NOTE: Could be parallelized.
  marks = Dict{Int64,NodeMarker}()
  const vs = nodes(this)
  const randomMarks = rand(NodeMarker, length(vs))
  for (i, v) in enumerate(vs)
    marks[v] = randomMarks[i]
  end
  marks
end

# Find all local minima of @values (which maps nodes to markers) in graph
# @this.  A local minimum is a node in @this whose neighbors in @this have
# value greater than or equal to it.
function findLocalMinima(this:: DependencyGraph, values:: Dict{Int64,NodeMarker})
  localMinima = Set{Int64}()
  for v in nodes(this)
    const value = values[v]
    foundSmallerNeighbor = false
    for u in neighbors(this, v)
      if value > values[u]
        foundSmallerNeighbor = true
        break
      end
    end
    if !foundSmallerNeighbor
      push!(localMinima, v)
    end
  end
  localMinima
end