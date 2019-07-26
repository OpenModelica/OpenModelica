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
include("./AbsynToSCode.jl")
using Absyn
using MetaModelica
HelloWorld = PROGRAM(list(CLASS("HelloWorld", false, false ,false, R_CLASS(), PARTS(list(), list(), list(PUBLIC(list(ELEMENTITEM(ELEMENT(false, NONE(), NOT_INNER_OUTER(), COMPONENTS(ATTR(false, false, NON_PARALLEL(), VAR(), BIDIR(), NONFIELD(), list()), TPATH(IDENT("Real"), NONE()), list(COMPONENTITEM(COMPONENT("x", list(), SOME(CLASSMOD(list(MODIFICATION(false, NON_EACH(), IDENT("start"), SOME(CLASSMOD(list(), EQMOD(INTEGER(1::ModelicaInteger), SOURCEINFO("/home/johti17/OpenModelica/OMCompiler/Examples/HelloWorld.mo", false, 2, 16, 2, 19)))), NONE(), SOURCEINFO("/home/johti17/OpenModelica/OMCompiler/Examples/HelloWorld.mo", false, 2, 10, 2, 19))), NOMOD()))), NONE(), NONE()))), SOURCEINFO("/home/johti17/OpenModelica/OMCompiler/Examples/HelloWorld.mo", false, 2, 3, 2, 20), NONE())), ELEMENTITEM(ELEMENT(false, NONE(), NOT_INNER_OUTER(), COMPONENTS(ATTR(false, false, NON_PARALLEL(), PARAM(), BIDIR(), NONFIELD(), list()), TPATH(IDENT("Real"), NONE()), list(COMPONENTITEM(COMPONENT("a", list(), SOME(CLASSMOD(list(), EQMOD(INTEGER(1::ModelicaInteger), SOURCEINFO("/home/johti1b/OpenModelica/OMCompiler/Examples/HelloWorld.mo", false, 3, 20, 3, 23))))), NONE(), NONE()))), SOURCEINFO("/home/johti17/OpenModelica/OMCompiler/Examples/HelloWorld.mo", false, 3, 3, 3, 23), NONE())))), EQUATIONS(list(EQUATIONITEM(EQ_EQUALS(CALL(CREF_IDENT("der", list()), FUNCTIONARGS(list(CREF(CREF_IDENT("x", list()))), list())), UNARY(UMINUS(), BINARY(CREF(CREF_IDENT("a", list())), MUL(), CREF(CREF_IDENT("x", list()))))), NONE(), SOURCEINFO("/home/johti17/OpenModelica/OMCompiler/Examples/HelloWorld.mo", false, 5, 3, 5, 19))))), list(), NONE()), SOURCEINFO("/home/johti17/OpenModelica/OMCompiler/Examples/HelloWorld.mo", false, 1, 1, 6, 15))), TOP())

AbsynToSCode.translateAbsyn2SCode(HelloWorld)

#include("./Util.jl")
