export ParallelLllKsatSolver, solve, IndependentSetFinder, MoserTardosIndependentSetFinder, SimpleChungIndependentSetFinder

using Problems

abstract IndependentSetFinder


# This is a _sequential_ implementation of a parallel algorithm.
# The algorithms here could be parallelized or distributed.  Currently we have
# not done that, but we have marked places that would need to be modified to 
# make algorithms run in parallel.

immutable ParallelLllKsatSolver <: Solver{KsatProblem}
  # An upper bound on the probability that we fail to find a satisfying
  # solution given that one exists.  This, along with the problem size,
  # determines the maximum number of iterations taken to find a solution.
  # When no satisfying solution exists,
  # the solver will always take that many iterations, since this solver
  # produces no certificate of failure.
  failureProbability:: Float64
  #NOTE: Needs to be parallelized if the rest of the algorithm is to be
  # parallelized.
  independentSetFinder:: IndependentSetFinder
end

function solve(this:: ParallelLllKsatSolver, problem:: KsatProblem)
  # See Moser and Tardos 2010, algorithm 1.1.
  const n = problem.numVariables
  println("Problem: $(string(problem))")
  assignment = uniformRandomAssignment(n)
  annotatedProblem = annotateKsatProblem(problem, assignment)
  #NOTE: Could be parallelized.
  const graph = makeKsatDependencyGraph(problem)
  const maxNumIterations = calculateNumIterations(this.independentSetFinder, problem, graph, this.failureProbability)
  println("Using at most $(maxNumIterations) iterations for $(problem.k)-SAT problem with $(n) variables and $(numClauses(problem)) clauses.")
  for i = 1:maxNumIterations
    #NOTE: Could be parallelized.
    const unsat = unsatisfiedClauses(annotatedProblem)
    if isempty(unsat)
      println("Found successful solution after $(i) iterations.")
      return toSuccessfulSolution(annotatedProblem)
    end
    const independentSet = find(this.independentSetFinder, inducedSubgraph(graph, unsat))
    #FIXME
    println("Found an independent set of size $(length(independentSet))")
    #NOTE: Could be parallelized.  For example, if clauses were distributed
    # across machines and separate variable states maintained per machine, each
    # time a clause i's variables are updated, the updates should be
    # communicated to each machine holding a clause that neighbors i in the
    # graph.
    for clauseIdx in independentSet
      const clause = problem.clauses[clauseIdx]
      for variable in clause.variables
        annotatedProblem.currentAssignment[variable] = randbool()
      end
      registerUpdate!(annotatedProblem, clause.variables)
    end
  end
  unsuccessfulKsatSolution(n)
end


function find(this:: IndependentSetFinder, graph:: DependencyGraph)
  raiseAbstract("find", this)
end

# Compute the number of iterations required by ParallelLllKsatSolver when
# using this method to find independent sets.
function calculateNumIterations(this:: IndependentSetFinder, problem:: KsatProblem, graph:: DependencyGraph, failureProbability:: Float64)
  raiseAbstract("calculateNumIterations", this)
end


# Use the Moser-Tardos algorithm, which finds a maximal independent set.
immutable MoserTardosIndependentSetFinder <: IndependentSetFinder end

function find(this:: MoserTardosIndependentSetFinder, graph:: DependencyGraph)
  maximalIndependentSet(graph)
end

function calculateNumIterations(this:: MoserTardosIndependentSetFinder, problem:: KsatProblem, graph:: DependencyGraph, failureProbability:: Float64)
  n = length(nodes(graph))
  d = maxDegree(graph)
  p = 2.0^(-1.0*problem.k)
  base = 1.0/(e*p*(d+1))
  #FIXME: Should involve failureProbability in some way, perhaps as log(1/failureProbability)^a for some a?
  max(100, int(ceil(log(base, n))))
end


# Use algorithm 1.2 in Chung et al's paper, which just finds an independent set
# by running one iteration of Luby's algorithm.  In principle, this algorithm
# requires e p (d+1)^2 < 1 to run in polynomial time.
immutable SimpleChungIndependentSetFinder <: IndependentSetFinder end

function find(this:: SimpleChungIndependentSetFinder, graph:: DependencyGraph)
  lubyIndependentSet(graph)
end

function calculateNumIterations(this:: SimpleChungIndependentSetFinder, problem:: KsatProblem, graph:: DependencyGraph, failureProbability:: Float64)
  n = length(nodes(graph))
  d = maxDegree(graph)
  p = 2.0^(-1.0*problem.k)
  base = 1.0/(e*p*(d+1))
  #FIXME: Should involve failureProbability in some way, perhaps as log(1/failureProbability)^a for some a?
  max(100, int(ceil(log(base, n))))
end
