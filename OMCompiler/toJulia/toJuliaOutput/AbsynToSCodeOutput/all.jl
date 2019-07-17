#= Note run from this folder=#
JIT_STACK_START_SIZE = 32768
JIT_STACK_MAX_SIZE = 1048576
Base.PCRE.JIT_STACK[] = ccall((:pcre2_jit_stack_create_8, Base.PCRE.PCRE_LIB), Ptr{Cvoid},
                              (Cint, Cint, Ptr{Cvoid}),
                              JIT_STACK_START_SIZE, JIT_STACK_MAX_SIZE, C_NULL)
ccall((:pcre2_jit_stack_assign_8, Base.PCRE.PCRE_LIB), Cvoid,
      (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}), Base.PCRE.MATCH_CONTEXT[], C_NULL, Base.PCRE.JIT_STACK[])

push!(LOAD_PATH, ".")
println(LOAD_PATH)
# include("./Absyn.jl")
#include("./AbsynUtil.jl")
# include("./List.jl")
#include("./SCode.jl")
include("./SCodeUtil.jl")
#include("./Util.jl")
