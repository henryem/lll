export SimpleMoserTardosSolver, SimpleMtSatLikeSolver, solve

using Utils
using Problems

# A <: VariableAssignment{V}
# C <: VariableConstraint{A, V}
immutable SimpleMoserTardosSolver{V <: VariableType, A <: VariableAssignment, C <: VariableConstraint} <: Solver{ProductMeasureCsp{V, A, C}}
end

typealias SimpleMtSatLikeSolver SimpleMoserTardosSolver{Binary, BinaryAssignment, SatClause}


# A <: VariableAssignment{V}
# C <: VariableConstraint{A, V}
function solve{V <: VariableType, A <: VariableAssignment, C <: VariableConstraint}(this:: SimpleMoserTardosSolver{V, A, C}, problem:: ProductMeasureCsp{V, A, C})
  # See Moser and Tardos 2010, algorithm 1.1.
  const n = numVars(problem)
  const maxNumIterations = 100000 #FIXME
  println("Using at most $(maxNumIterations) iterations for $(string(problem)).")
  assignment = jointSample(problem)
  for i = 1:maxNumIterations
    const unsat = filter(constraint -> isSatisfied(constraint, assignment), constraints(problem))
    if isempty(unsat)
      println("Found successful solution after $(i) iterations.")
      return successfulSolution(assignment)
    end
    const constraintIdx = first(unsat)
    const constraint = constraints(problem)[constraintIdx]
    marginalSample!(problem, vbl(constraint), assignment)
  end
  unsuccessfulSolution(A)
end

# solve(), specialized to SAT and k-SAT for performance.
#TODO: A lot of copied code.  Could probably merge this with the above.
# I think the method of tracking unsatisfied constraints is completely general,
# and we can get rid of this special case entirely.
function solve(this:: SimpleMtSatLikeSolver, problem:: SatLikeProblem)
  # See Moser and Tardos 2010, algorithm 1.1.
  const n = numVars(problem)
  const maxNumIterations = 100000 #FIXME
  println("Using at most $(maxNumIterations) iterations for $(string(problem)).")
  assignment = jointSample(problem)
  annotatedProblem = annotateSatProblem(problem, assignment)
  for i = 1:maxNumIterations
    const unsat = unsatisfiedClauses(annotatedProblem)
    if isempty(unsat)
      println("Found successful solution after $(i) iterations.")
      return successfulSolution(annotatedProblem.currentAssignment)
    end
    const constraintIdx = first(unsat)
    const constraint = constraints(problem)[constraintIdx]
    const vbls = vbl(constraint)
    marginalSample!(problem, vbls, assignment)
    registerUpdate!(annotatedProblem, vbls)
  end
  unsuccessfulSolution(BinaryAssignment)
end
