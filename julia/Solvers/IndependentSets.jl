export maximalIndependentSet, lubyIndependentSet

using Distributions

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
  const marked = markNodesRandomly(this)
  findLocalMinima(marked)
end

# Assign a random marker of type NodeMarker to each vertex of @this.
function markNodesRandomly(this:: DependencyGraph)
  markNodesRandomly(this, DiscreteUniform(typemin(NodeMarker), typemax(NodeMarker)))
end

# Assign IID draws from @distribution to each node of @this.
# @param distribution should be a distribution on elements of type NodeMarker.
function markNodesRandomly(this:: DependencyGraph, distribution:: Sampleable{Univariate,Discrete})
  #NOTE: Could be parallelized.
  marks = Dict{Int64,NodeMarker}()
  const vs = nodes(this)
  const randomMarks = rand(distribution, length(vs))
  for (i, v) in enumerate(vs)
    marks[v] = randomMarks[i]
  end
  MarkedGraph{NodeMarker}(this, marks)
end

# Find all strict local minima of @values (which maps nodes to markers) in graph
# @this.  A strict local minimum is a node in @this whose neighbors in @this
# have value greater than it.
function findLocalMinima(this:: MarkedGraph{NodeMarker})
  findLocalMinima(this, <)
end

# Find all strict local minima of @values (which maps nodes to markers) in graph
# @this.  A strict local minimum is a node in @this whose neighbors in @this
# have value greater than it according to @lessThanFunc.
# @param lessThanFunc should be a binary operator like < that induces a
# total order on nodes.
function findLocalMinima(this:: MarkedGraph{NodeMarker}, lessThanFunc:: Function)
  localMinima = Set{Int64}()
  for v in nodes(this.graph)
    const mark = this.marks[v]
    foundSmallerNeighbor = false
    for u in neighbors(this.graph, v)
      #TODO: Probably slow; there is a library that uses the type system to
      # avoid function calls like this for common functions, but I do not 
      # remember its name.
      # 
      # Read this as "If myMark >= neighborMark, I am not a local minimum."
      if !lessThanFunc(mark, this.marks[u])
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

# Find all strict local maxima of @values (which maps nodes to markers) in graph
# @this.
function findLocalMaxima(this:: MarkedGraph{NodeMarker})
  findLocalMinima(this, >)
end