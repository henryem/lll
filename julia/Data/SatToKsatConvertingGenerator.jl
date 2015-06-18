export SatToKsatConvertingGenerator, generate

using GeneratedData
using Problems

immutable SatToKsatConvertingGenerator <: DataGenerator
  satGenerator:: DataGenerator
  strategy:: SatToKsatStrategy
end

function GeneratedData.generate(this:: SatToKsatConvertingGenerator)
  satToKsat(generate(this.satGenerator), this.strategy)
end
