export BinaryAssignment, defaultAssignment, uniformRandomBinaryAssignment, emptyBinaryAssignment

type BinaryAssignment <: VariableAssignment{Binary}
  vars:: BitVector
end

function BinaryAssignment(vars:: AbstractVector{Bool})
  BinaryAssignment(bitpack(vars))
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