export SphericalGaussianLeastSquaresGenerator, generate

using Distributions
using Problems

immutable SphericalGaussianLeastSquaresGenerator <: DataGenerator
  n1:: Int64 # Number of rows in A (number of objective components)
  n2:: Int64 # Number of columns in A (dimension of solution)
  r:: Float64 # Size of elements of A
  rb:: Float64 # Size of elements of b
  mb:: Float64 # Offset (mean) of elements of b
end

function generate(this:: SphericalGaussianLeastSquaresGenerator)
  const objectives = map(1:this.n1) do objectiveIdx
    ai = this.r*randn(this.n2)
    bi = this.rb*randn() + this.mb
    LeastSquaresObjectiveFunction(ai, bi)
  end
  LeastSquaresProblem(this.n1, objectives)
end