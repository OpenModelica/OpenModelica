using OMJulia: OMCSession, sendExpression

JIT_STACK_START_SIZE = 32768
JIT_STACK_MAX_SIZE = 1048576
Base.PCRE.JIT_STACK[] = ccall((:pcre2_jit_stack_create_8, Base.PCRE.PCRE_LIB), Ptr{Cvoid},
                              (Cint, Cint, Ptr{Cvoid}),
                              JIT_STACK_START_SIZE, JIT_STACK_MAX_SIZE, C_NULL)
ccall((:pcre2_jit_stack_assign_8, Base.PCRE.PCRE_LIB), Cvoid,
      (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}), Base.PCRE.MATCH_CONTEXT[], C_NULL, Base.PCRE.JIT_STACK[])

include("metaModelicaToJulia.jl")

function main()
  frontEndPath = abspath("../Compiler/FrontEnd/")
  omc = size(ARGS, 1) == 1 ? OMCSession(ARGS[1]) : OMCSession()
  files = [
    "\$frontEndPath\/Absyn.mo",
    "\$frontEndPath\/AbsynUtil.mo",
    "\$frontEndPath\/Graphviz.mo"
  ]
  metaModelicaToJulia(files, omc, "toJulia/")
end

main()
