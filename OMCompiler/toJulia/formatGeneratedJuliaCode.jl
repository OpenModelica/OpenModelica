#=
Checks if it is possible to parse a file using Meta.Parse
if so attempts to parse the same file using CSTParser.

If  the above suceeds formats the files using YASStyle.
=#
import CSTParser
using JuliaFormatter
@info length(ARGS)
if length(ARGS) < 1
  println("Specify a path to a folder to format\n")
  exit(1)
end

PATH = ARGS[1]

#= Test and see if generated files follow Julia syntax =#
for f in filter(x -> endswith(x, "jl"), readdir(PATH))
  local fullPath = abspath("$PATH")
  println("Parsing using CSTParser: $fullPath...")
  fileContents = read("$(fullPath)/$(f)", String)
  println(abspath("$f"))
  CSTP_SUCEED = false
  try
    Meta.parse(fileContents)
   #CSTParser.parse(fileContents, true)
  catch error
    println("Error parsing: $f")
    @info error
  end
end

format(PATH, style=YASStyle(), indent=2,
    always_for_in = false,
    whitespace_typedefs = true,
    whitespace_ops_in_indices = true,
    remove_extra_newlines = true,
    import_to_using = false,
    pipe_to_function_call = false,
    short_to_long_function_def = false,
    always_use_return = true)
exit(0)
