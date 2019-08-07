module OpenModelicaParser
  import Absyn
  using MetaModelica

  struct ParseError
  end

  function isDerCref(exp::Absyn.Exp)::Bool
    @match exp begin
      Absyn.CALL(Absyn.CREF_IDENT("der",  nil()), Absyn.FUNCTIONARGS(Absyn.CREF(__) <|  nil(),  nil()))  => true
      _ => false
    end
  end

  if Sys.iswindows()
    const _libpath = joinpath(dirname(dirname(@__DIR__)),"Parser","libomparse-julia.dll")
  else
    const _libpath = joinpath(dirname(dirname(@__DIR__)),"Parser","libomparse-julia.so")
  end 
  
  function parseFile(fileName::String)::Absyn.Program
    res = ccall((:parseFile,_libpath),Any,(String,),fileName)
    if res == nothing
      throw(ParseError())
    end
    res
  end
end
