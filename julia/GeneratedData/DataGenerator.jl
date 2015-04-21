export DataGenerator, generate

abstract DataGenerator

function generate(this:: DataGenerator)
  raiseAbstract("generate", this)
end