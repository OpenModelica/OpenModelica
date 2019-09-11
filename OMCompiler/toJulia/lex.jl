using Glob
import Automa

function bytesToPositions(data)
  data_raw = Vector{UInt8}(data)
  p_end = p_eof = sizeof(data)
  positions = Array{Int,2}(undef, p_end, 2)
  p = pos = 1
  row = 1
  col = 1
  while pos ≤ p_eof
    positions[pos,1:2] = [row,col]
    col = col + 1
    inc = 1
    if data_raw[pos] == Int('\n')
      col = 0
      row = row + 1
    elseif data_raw[pos] & 0x80 == 0x00
      # 1 byte
    elseif data_raw[pos] & 0xe0 == 0xc0
      # 2 byte sequence
      inc = 2
    elseif data_raw[pos] & 0xf0 == 0xe0
      # 3 byte sequence
      inc = 3
    elseif data_raw[pos] & 0xf8 == 0xf0
      # 4 byte sequence
      inc = 4
    else
      # Invalid
      throw(LexerError("Could not parse UTF-8 String, but Julia says the String is UTF-8..."))
    end
    pos = pos + inc
  end
  positions
end

include("tokens.jl")
include("generated_lexer.jl")

function scanMSL()
  for f in glob("../build/lib/omlibrary/Modelica 3.2.3/**/*.mo")
    tokens = tokenize(f)
  end
end

# using Profile

println("Serial MSL lexer")
scanMSL()
# Profile.clear_malloc_data()
scanMSL()
exit(0)
#@time scanMSL()

function scanMSLParallel()
  files = glob("../build/lib/omlibrary/Modelica 3.2.3/**/*.mo")
  Threads.@threads for i = 1:length(files)
    tokenize(files[i])
  end
end

# Start with env.var: JULIA_NUM_THREADS=4
println("Parallel MSL lexer")
@time scanMSLParallel()
#@time scanMSLParallel()
#@time scanMSLParallel()
