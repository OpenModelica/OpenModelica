using OMJulia: OMCSession, sendExpression

macro uniontype(expr)
  quote
    abstract type $expr end;
  end
end

function metaModelicaToJulia(files, omc, outputdir)
  @assert sendExpression(omc, "setCommandLineOptions(\"-g=MetaModelica\")")
  for file in files
    println(file)
    base = Base.Filesystem.basename(file)::AbstractString
    sendExpression(omc, "clear()")
    println(sendExpression(omc, "getSettings()"))
    @assert sendExpression(omc, "loadFile(\"$file\")")
    try
      x = sendExpression(omc, "OpenModelica.Scripting.Experimental.toJulia()")
      write(open("$outputdir/$(base[1:end-3]).jl", "w"), x)
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
  all = open("$outputdir/all.jl", "w")
  for file in files
    base = Base.Filesystem.basename(file)
    write(all, "include(\"$(base[1:end-3]).jl\")\n")
  end
  return something
end
