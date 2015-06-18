using ArgParse
using GeneratedData, Problems, Solvers, Utils

using Gadfly


function parseArgs()
  s = ArgParseSettings()
  
  @add_arg_table s begin
    "--data-generator", "-d"
      help = "the DataGenerator to use, a Julia string"
    "--seed", "-e"
      help = "the random seed" #FIXME
      arg_type = Int
  end

  return parse_args(s)
end



function computeDegreeStatistics(problemGenerator:: DataGenerator)
  maxDegrees = []
  averageDegrees = []
  for i = 1:1000
    const problem = generate(problemGenerator)
    const problemGraph = makeGraphWithCriterion(problem, SharedVariable)
    push!(maxDegrees, maxDegree(problemGraph))
    push!(averageDegrees, totalDegree(problemGraph) / length(nodes(problemGraph)))
  end
  println(maxDegrees)
  println(averageDegrees)
end


function independenceLrTestStatistic(samples:: AbstractVector{AbstractVector{Float64}})
  const numSamples = length(samples)
  const n = numSamples > 0 ? length(samples[1]) : 0
  const jointEmpiricalDist = [k => v / numSamples for (k, v) in countUniques(samples)]
  const dependentLikelihood = mapreduce(p -> p*log(p), +, values(jointEmpiricalDist))
  const marginalEmpiricalDists = map(1:n) do edgeIdx
    mapreduce(sample -> sample[edgeIdx] / numSamples, +, samples)
  end
  const nullLikelihood = mapreduce(p*log(p)+(1-p)*log(1-p), +, marginalEmpiricalDists)
  dependentLikelihood / nullLikelihood
end


function testEdgeMutualIndependence(problemGenerator:: DataGenerator, edgesToTest:: AbstractVector{(Int64,Int64)})
  # We test the null hypothesis that the presence of @edgesToTest are mutually 
  # independent under the distribution @problemGenerator.
  # 
  # We use a likelihood ratio test.  Let n = |edgesToTest|.  The test statistic 
  # is:
  #   [\sup_{probability measures m on {0,1}^n} l_m(data)] /
  #   [\sup_{product measures m on {0,1}^n}] l_m(data)]
  #   = f(data) / g(data),
  # where:
  #   f(data) = l_\hat{m}(data),
  # and
  #   g(data) = l_{\prod_i \hat{m}_i}(data)
  # 
  # Next we approximate the distribution of this statistic under the null, and 
  # we reject if the test statistic is large.  Specifically, we take a sample
  # from the problem distribution, then resample new edge presence vectors
  # by sampling independently from the marginal distributions on edge presences.
  # Probably there is a simple closed form for the distribution of the test
  # statistic, but this is easy enough.
  
  const n = length(edgesToTest)
  const numSamples = 1000
  const samples = map(1:numSamples) do i
    const g = makeCspDependencyGraph(generate(problemGenerator))
    map(e -> float(hasEdge(g, e)), edgesToTest)
  end
  actualLr = independenceLrTestStatistic(samples)
  
  const numResamples = 1000
  const marginalEmpiricalDists = map(1:n) do edgeIdx
    mapreduce(sample -> sample[edgeIdx] / numSamples, +, samples)
  end
  const resampleLrs = map(1:numResamples) do resampleIdx
    resample = map(1:numSamples) do sampleIdx
      # Resample under the independence assumption.
      
    end
    independenceLrTestStatistic(resample)
  end
end


function run()
  const args = parseArgs()
  const problemGenerator = eval(parse(args["data-generator"]))
  computeDegreeStatistics(problemGenerator)
end

run()
