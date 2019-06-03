using OMJulia: OMCSession, sendExpression

JIT_STACK_START_SIZE = 32768
JIT_STACK_MAX_SIZE = 1048576
Base.PCRE.JIT_STACK[] = ccall((:pcre2_jit_stack_create_8, Base.PCRE.PCRE_LIB), Ptr{Cvoid},
                         (Cint, Cint, Ptr{Cvoid}),
                         JIT_STACK_START_SIZE, JIT_STACK_MAX_SIZE, C_NULL)
ccall((:pcre2_jit_stack_assign_8, Base.PCRE.PCRE_LIB), Cvoid,
      (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}), Base.PCRE.MATCH_CONTEXT[], C_NULL, Base.PCRE.JIT_STACK[])


function main()
  omc=OMCSession()
  sendExpression(omc, "setCommandLineOptions(\"-g=MetaModelica\")")
  files = [
    "FrontEnd/Absyn.mo",
    "FrontEnd/AbsynUtil.mo",
    "FrontEnd/Graphviz.mo"
  ]
  for file in files
    print(file)
    base = Base.Filesystem.basename(file)
    sendExpression(omc, "clear()")
    @assert sendExpression(omc, "loadFile(\"Compiler/$file\")")
    try
      x = sendExpression(omc, "OpenModelica.Scripting.Experimental.toJulia()")
      write(open("toJulia/$(base[1:end-3]).jl", "w"),x)
      println(x)
    catch e
      bt = backtrace()
      msg = sprint(showerror, e, bt)
      println(msg)
      println(sendExpression(omc, "getErrorString()"))
      return nothing
    end
    println(" OK")
  end
  all = open("toJulia/all.jl", "w")
  for file in files
    base = Base.Filesystem.basename(file)
    write(all, "include(\"$(base[1:end-3]).jl\")")
  end
end

main()
