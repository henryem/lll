#DEPRECATED

export ParallelLllKsatSolver, solve
export IndependentSetFinder, MoserTardosIndependentSetFinder, SimpleChungIndependentSetFinder, WeakMisFinder, buildFinderFunc, calculateNumIterations

using Problems
using Distributions


abstract IndependentSetFinder

# Return a function from a subgraph of @problemGraph to an independent set in
# that subgraph.
function buildFinderFunc(this:: IndependentSetFinder, problemGraph:: DependencyGraph)
  raiseAbstract("buildFinderFunc", this)
end

# Compute the number of iterations required by ParallelLllKsatSolver when
# using this method to find independent sets.
function calculateNumIterations(this:: IndependentSetFinder, problem:: KsatProblem, graph:: DependencyGraph)
  raiseAbstract("calculateNumIterations", this)
end


# This is a _sequential_ implementation of a parallel algorithm.
# The algorithms here could be parallelized or distributed.  Currently we have
# not done that, but we have marked places that would need to be modified to 
# make algorithms run in parallel.

immutable ParallelLllKsatSolver <: Solver{KsatProblem}
  #NOTE: Needs to be parallelized if the rest of the algorithm is to be
  # parallelized.
  independentSetFinder:: IndependentSetFinder
end

function solve(this:: ParallelLllKsatSolver, problem:: KsatProblem)
  # See Moser and Tardos 2010, algorithms 1 and 2.
  const n = problem.numVariables
  println("Problem: $(string(problem))")
  assignment = uniformRandomBinaryAssignment(n)
  annotatedProblem = annotateSatProblem(problem, assignment)
  #NOTE: Could be parallelized.
 const graph = makeGraphWithCriterion(problem, SharedVariable)
 const maxNumIterations = calculateNumIterations(this.independentSetFinder, problem, graph)
 const independentSetFunc = buildFinderFunc(this.independentSetFinder, graph)
 println("Using at most $(maxNumIterations) iterations for $(problem.k)-SAT problem with $(n) variables and $(numClauses(problem)) clauses.")
 for i = 1:maxNumIterations
   #NOTE: Could be parallelized.
   const unsat = unsatisfiedClauses(annotatedProblem)
   if isempty(unsat)
     println("Found successful solution after $(i) iterations.")
     return successfulSolution(annotatedProblem)
   end
   const independentSet = independentSetFunc(inducedSubgraph(graph, unsat))
    println("Using an independent set of size $(length(independentSet)) on iteration $i")
    # NOTE: Could be parallelized.  For example, if clauses were distributed
    # across machines and separate variable states maintained per machine, each
    # time a clause i's variables are updated, the updates should be
    # communicated to each machine holding a clause that neighbors i in the
    # graph.
   for clauseIdx in independentSet
     const clause = problem.clauses[clauseIdx]
     for variable in vbl(clause)
       annotatedProblem.currentAssignment[variable] = randbool()
     end
     registerUpdate!(annotatedProblem, vbl(clause))
   end
 end
 unsuccessfulKsatSolution(n)
end


# Use the Moser-Tardos algorithm, which finds a maximal independent set.  This
# algorithm is guaranteed to find a solution with high probability (for
# reasonable iteration counts) when e p (d+1) < 1.
immutable MoserTardosIndependentSetFinder <: IndependentSetFinder end

function buildFinderFunc(this:: MoserTardosIndependentSetFinder, graph:: DependencyGraph)
  return subgraph -> maximalIndependentSet(subgraph)
end

function calculateNumIterations(this:: MoserTardosIndependentSetFinder, problem:: KsatProblem, graph:: DependencyGraph)
  n = length(nodes(graph))
  d = maxDegree(graph)
  p = 2.0^(-1.0*problem.k)
  base = 1.0/(e*p*(d+1))
  #HACK
  max(100, int(ceil(log(base, n))))
end


# Use algorithm 2 in Chung et al's paper, which just finds an independent set
# by running one iteration of Luby's algorithm, using the same random node
# markers for every iteration.  In principle, this algorithm
# is only proven to find a solution with high probability (for reasonable
# iteration counts) when e p (d+1)^2 < 1, which is stricter than the 
# Moser-Tardos algorithm.  In practice it may be faster than the Moser-Tardos
# algorithm, since it is probably wasteful to perform many rounds of 
# communication to find larger independent sets.
immutable SimpleChungIndependentSetFinder <: IndependentSetFinder end

function buildFinderFunc(this:: SimpleChungIndependentSetFinder, graph:: DependencyGraph)
  const markings = markNodesRandomly(graph)
  return subgraph -> findLocalMinima(subgraph, markings)
end

function calculateNumIterations(this:: SimpleChungIndependentSetFinder, problem:: KsatProblem, graph:: DependencyGraph)
  n = length(nodes(graph))
  d = maxDegree(graph)
  p = 2.0^(-1.0*problem.k)
  base = 1.0/(e*p*(d+1))
  #HACK
  max(100, int(ceil(log(base, n))))
end


# The independent set algorithm by Chung et al (algorithm 3).  In theory,
# this takes only polylog(d) iterations to find a good-enough independent set,
# while algorithms that actually find maximal independent sets must take a
# number of iterations that depends (perhaps weakly) on the graph size n.
immutable WeakMisFinder <: IndependentSetFinder end

function buildFinderFunc(this:: WeakMisFinder, graph:: DependencyGraph)
  const d = maxDegree(graph)
  const maxNumIterations = 4*e^2*log(2*e*(d+1.0)^4)
  
  function findIndependentSet(subgraph:: DependencyGraph)
    # This variable is called S in Chung et al.
    independentSet = Set{Int64}()
    for epoch = 1:maxNumIterations
      # We examine the remaining graph after removing everything neighboring a
      # member of the independent set we are growing.
      #NOTE: Could be parallelized.
      candidateNodes = setdiff(nodes(subgraph), neighborhood(subgraph, independentSet))
      if isempty(candidateNodes)
        break
      end
      # This variable is called G' in Chung et al.
      candidateSubgraph = inducedSubgraph(subgraph, candidateNodes)
      # In each phase, we find high-degree vertices (with the threshold lowered
      # in each phase); sample some independent elements with a simplified
      # version of Luby's algorithm, with fewer nodes assigned high rank on
      # the high-degree phases; and eliminate the vertices we examined, plus the
      # neighborhood of any vertices we selected for our independent set.
      # There is one communication step per phase, since each node needs to know 
      # its neighbors' ranks in the Luby-like step.
      for phase = 1:int(ceil(log(d)))
        #NOTE: Could be parallelized.
        minDegree = d / 2^phase
        # This variable is called V_i in Chung et al.
        # In this simplified version of Luby's algorithm, each node is marked
        # with a 0 or 1, and only nodes that are marked 1 and have no neighbors
        # marked 1 are chosen.  (So it is Luby's algorithm with the order on
        # marks switched, the marks limited to {0,1}, and a nonuniform sampling
        # distribution for the marks.)
        samplingProbability = 1.0/(d*2^(-phase+1.0)+1.0)
        dist = Bernoulli(samplingProbability)
        
        #NOTE: Could be parallelized.
        marked = markNodesRandomly(candidateSubgraph, dist)
        #NOTE: Could be parallelized.
        localMaxima = findLocalMaxima(marked)
        #NOTE: Could be parallelized.
        independentSet = union(independentSet, localMaxima)
        # We remove all high-degree nodes, and also the inclusive neighborhood
        # (that is, the nodes and the union of their neighbors) of nodes that 
        # were added to the independent set on this iteration.
        #NOTE: Could be parallelized.
        nodesToRemove = union(
          neighborhood(candidateSubgraph, localMaxima),
          filter(v -> degree(candidateSubgraph, v) >= minDegree, candidateNodes))
        #NOTE: Could be parallelized.
        candidateNodes = setdiff(candidateNodes, nodesToRemove)
        candidateSubgraph = inducedSubgraph(subgraph, candidateNodes)
      end
      # Add in any nodes with degree 0 in the subgraph.  We did not iterate over
      # such nodes in any phase above; all other nodes have been removed from
      # candidateNodes.
      union!(independentSet, candidateNodes)
    end
    independentSet
  end
  
  return findIndependentSet
end

function calculateNumIterations(this:: WeakMisFinder, problem:: KsatProblem, graph:: DependencyGraph)
  n = length(nodes(graph))
  d = maxDegree(graph)
  p = 2.0^(-1.0*problem.k)
  base = 1.0/(e*p*(d+1))
  #FIXME: If base < 1, we no longer have the theoretical guarantee that this is
  # enough iterations, and the formula becomes garbage (it gives us a negative
  # number.  We still care about solving such problems in practice, so we need
  # some alternative heuristic for stopping.  For now we just use 1000
  # iterations, which is totally arbitrary and wrong.
  max(1000, int(ceil(log(d+1, n))), int(ceil(log(base, n))))
end