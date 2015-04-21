export ExhaustiveKsatSolver, solve

immutable ExhaustiveKsatSolver <: KsatSolver end

function solve(this:: ExhaustiveKsatSolver, problem:: KsatProblem)
  const n = problem.numVariables
  assignment = BitVector(n)
  satisfyingAssignment = uniformRandomAssignment(n)
  numSatisfyingSolutions = 0
  const numPotentialSolutions = 2^n
  for binaryAssignment:: Uint64 = 1:numPotentialSolutions
    #TODO: Could be done much faster with a Gray code or a direct conversion
    # from binary to BitVector.
    for variableIdx = 1:n
      assignment[variableIdx] = (binaryAssignment >> (variableIdx-1)) & 0x1
    end
    if checkSuccess(assignment, problem)
      if numSatisfyingSolutions == 0
        satisfyingAssignment = deepcopy(assignment)
      end
      numSatisfyingSolutions += 1
    end
  end
  return AnnotatedKsatSolution(satisfyingAssignment, numSatisfyingSolutions > 0, numSatisfyingSolutions, numPotentialSolutions)
end