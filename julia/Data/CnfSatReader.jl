export CnfSatReader, generate

using GeneratedData
using Distributions
using Problems

immutable CnfSatReader <: DataGenerator
  path:: String
end

function decompressed(f:: Function, path:: String)
  if endswith(path, ".lzma")
    open(f, `lzcat $path`, "r", STDIN)
  else
    open(f, path, "r", STDIN)
  end
end

function readProblemDescription!(cnfFile)
  for (lineIdx, line) in enumerate(eachline(cnfFile))
    if beginswith(line, "c")
      continue
    elseif beginswith(line, "p cnf")
      const problemDescriptionMatch = match(r"([0-9]+) ([0-9]+)", line, length("p cnf")+1)
      const n = int(problemDescriptionMatch.captures[1])
      const m = int(problemDescriptionMatch.captures[2])
      return (n, m)
    else
      error("Cannot process file $(f): Syntax error at line $(lineIdx) ($(line)).")
    end
  end
end

function GeneratedData.generate(this:: CnfSatReader)
  decompressed(this.path) do file
    const n, m = readProblemDescription!(file)
    const clauses = map(eachline(file)) do line
      # The last number on each line is a 0, which is to be ignored.
      const varStrings = split(line, " ")[1:(end-1)]
      # We use 1-based-indexing because Julia is weird that way.
      const vars = map(v -> abs(int(v)), varStrings)
      const signs = map(v -> !beginswith(v, "-"), varStrings)
      SatClause(vars, signs)
    end
    assert(length(clauses) == m)
    assert(maximum(map(clause -> maximum(vbl(clause)), clauses)) <= n)
    SatProblem(n, clauses)
  end
end

