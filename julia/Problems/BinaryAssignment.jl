export BinaryAssignment, defaultAssignment, uniformRandomBinaryAssignment, emptyBinaryAssignment

type BinaryAssignment <: VariableAssignment{Binary}
  #FIXME: Maybe should use a concrete type here for performance.
  vars:: AbstractVector{Bool}
end

function defaultAssignment(numVariables:: Int64, :: Type{BinaryAssignment})
  emptyBinaryAssignment(numVariables)
end

function uniformRandomBinaryAssignment(numVariables:: Int64)
  BinaryAssignment(randbool(numVariables))
end

function emptyBinaryAssignment(numVariables:: Int64)
  BinaryAssignment(falses(numVariables))
end