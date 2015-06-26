export RealAssignment, defaultAssignment

type RealAssignment <: VariableAssignment{Real}
  vars:: Vector{Float64}
end

function defaultAssignment(numVariables:: Int64, :: Type{BinaryAssignment})
  zeroAssignment(numVariables)
end

function zeroAssignment(numVariables:: Int64)
  RealAssignment(zeros(Float64, numVariables))
end