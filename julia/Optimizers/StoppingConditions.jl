export SolverState
export RichSolverState
export SimpleSolverState, next!
export StoppingCondition, shouldStop
export StopAfterKIterations


abstract SolverState


type RichSolverState <: SolverState
  x:: Vector{Float64}
  lastXDist:: Float64
  residual:: Float64
  k:: Int64
end


type SimpleSolverState <: SolverState
  k:: Int64
end

function next!(this:: SimpleSolverState)
  this.k += 1
end


abstract StoppingCondition{S <: SolverState}

function shouldStop{S <: SolverState}(this:: StoppingCondition{S}, s:: S)
  raiseAbstract("shouldStop", this)
end


immutable StopAfterKIterations <: StoppingCondition{SimpleSolverState}
  k:: Int64
end

function shouldStop(this:: StopAfterKIterations, s:: SimpleSolverState)
  s.k > this.k
end