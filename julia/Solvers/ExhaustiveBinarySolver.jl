export ExhaustiveBinarySolver, solve

immutable ExhaustiveBinarySolver <: Solver{Problem{BinaryAssignment}} end

function solve(this:: ExhaustiveBinarySolver, problem:: Problem{BinaryAssignment})
  const n = numVars(problem)
  assignment = defaultAssignment(n, BinaryAssignment)
  assignmentBits = assignment.vars
  satisfyingAssignment = defaultAssignment(n, BinaryAssignment)
  numSatisfyingSolutions = 0
  const numPotentialSolutions = 2^n

  for binaryAssignment = 0:(numPotentialSolutions-1)
    #TODO: Could be done much faster with a Gray code or a direct conversion
    # from binary to BitVector.
    for variableIdx = 1:n
      assignmentBits[variableIdx] = (binaryAssignment >> (variableIdx-1)) & 0x1
    end
    if isSatisfied(problem, assignment)
      if numSatisfyingSolutions == 0
        satisfyingAssignment = deepcopy(assignment)
      end
      numSatisfyingSolutions += 1
    end
  end

  return AnnotatedKsatSolution(satisfyingAssignment, numSatisfyingSolutions > 0, numSatisfyingSolutions, numPotentialSolutions)
end