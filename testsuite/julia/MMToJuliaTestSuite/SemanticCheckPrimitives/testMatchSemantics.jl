#= TODO add models as includes=#
module TestMatch
#= We might fail here already =#
include("../OutputMatchExpressions/MatchExpressions.jl")
include("../testsuiteUtil.jl")
using Absyn
using Test
using .MatchExpressions
using .MMToJuliaTestSuiteUtil
using MetaModelica

#= Try creating the different components of the empty Model M=#

#=
  model M
  end M;
=#

@testset "Simple instantiation of Absyn elements" begin
  #=Try to instantiate a model restriction =#
  @test_nothrow_nowarn begin
    Absyn.R_MODEL()
  end

  #= Try to instantiate a source info=#
  @test_nothrow_nowarn begin
    SOURCEINFO("/home/johti17/OpenModelica/OMCompiler/Examples/M.mo", false, 1, 1, 2, 6)
  end

  #= Try to instantiate a Absyn.TOP =#
  @test_nothrow_nowarn begin
    Absyn.TOP()
  end


  # Try to instantiate the public part of Model M =#
  @test_nothrow_nowarn begin
    Absyn.PUBLIC(list())
  end

  #= Try to instantiate the inner of parts =#
  @test_nothrow_nowarn begin
    list(Absyn.PUBLIC(list()))
  end

  @test_nothrow_nowarn begin
    SOURCEINFO("/home/johti17/OpenModelica/OMCompiler/Examples/M.mo", true, 1, 1, 2, 6)
  end

  @test_nothrow_nowarn begin
    PARTS(list(), list(), list(PUBLIC(list())), list(), NONE())
  end

  @test_nothrow_nowarn begin
    CLASS("M", false, false, false, R_MODEL(), PARTS(list(), list(), list(PUBLIC(list())), list(), NONE()), SOURCEINFO("/home/johti17/OpenModelica/OMCompiler/Examples/M.mo", true, 1, 1, 2, 6))
  end

  #= Try to instantiate parts of Model M =#
  @test_nothrow_nowarn begin
    PROGRAM(list(CLASS("M", false, false,false, R_MODEL(), PARTS(list(), list(), list(PUBLIC(list())), list(), NONE()), SOURCEINFO("/home/johti17/OpenModelica/OMCompiler/Examples/M.mo", true, 1, 1, 2, 6))), TOP())
  end

  @test_nothrow_nowarn begin
    CREF_IDENT("a", list())
  end
end #= End simple init =#

@testset "Try to init HelloWorld model" begin
  @test_nothrow_nowarn begin
    PROGRAM(list(CLASS("HelloWorld", false, false ,false, R_CLASS(), PARTS(list(), list(), list(PUBLIC(list(ELEMENTITEM(ELEMENT(false, NONE(), NOT_INNER_OUTER(), COMPONENTS(ATTR(false, false, NON_PARALLEL(), VAR(), BIDIR(), NONFIELD(), list()), TPATH(IDENT("Real"), NONE()), list(COMPONENTITEM(COMPONENT("x", list(), SOME(CLASSMOD(list(MODIFICATION(false, NON_EACH(), IDENT("start"), SOME(CLASSMOD(list(), EQMOD(INTEGER(1::ModelicaInteger), SOURCEINFO("/home/johti17/OpenModelica/OMCompiler/Examples/HelloWorld.mo", false, 2, 16, 2, 19)))), NONE(), SOURCEINFO("/home/johti17/OpenModelica/OMCompiler/Examples/HelloWorld.mo", false, 2, 10, 2, 19))), NOMOD()))), NONE(), NONE()))), SOURCEINFO("/home/johti17/OpenModelica/OMCompiler/Examples/HelloWorld.mo", false, 2, 3, 2, 20), NONE())), ELEMENTITEM(ELEMENT(false, NONE(), NOT_INNER_OUTER(), COMPONENTS(ATTR(false, false, NON_PARALLEL(), PARAM(), BIDIR(), NONFIELD(), list()), TPATH(IDENT("Real"), NONE()), list(COMPONENTITEM(COMPONENT("a", list(), SOME(CLASSMOD(list(), EQMOD(INTEGER(1::ModelicaInteger), SOURCEINFO("/home/johti1b/OpenModelica/OMCompiler/Examples/HelloWorld.mo", false, 3, 20, 3, 23))))), NONE(), NONE()))), SOURCEINFO("/home/johti17/OpenModelica/OMCompiler/Examples/HelloWorld.mo", false, 3, 3, 3, 23), NONE())))), EQUATIONS(list(EQUATIONITEM(EQ_EQUALS(CALL(CREF_IDENT("der", list()), FUNCTIONARGS(list(CREF(CREF_IDENT("x", list()))), list())), UNARY(UMINUS(), BINARY(CREF(CREF_IDENT("a", list())), MUL(), CREF(CREF_IDENT("x", list()))))), NONE(), SOURCEINFO("/home/johti17/OpenModelica/OMCompiler/Examples/HelloWorld.mo", false, 5, 3, 5, 19))))), list(), NONE()), SOURCEINFO("/home/johti17/OpenModelica/OMCompiler/Examples/HelloWorld.mo", false, 1, 1, 6, 15))), TOP())
  end
end #= End HelloWorld Init =#


@testset "Create Circle Model" begin
  @test_nothrow_nowarn begin PROGRAM(list(CLASS("Circle", false, false ,false, R_MODEL(), PARTS(list(), list(), list(PUBLIC(list(LEXER_COMMENT("// Circle model"), ELEMENTITEM(ELEMENT(false, NONE(), NOT_INNER_OUTER(), COMPONENTS(ATTR(false, false, NON_PARALLEL(), VAR(), BIDIR(), NONFIELD(), list()), TPATH(IDENT("Real"), NONE()), list(COMPONENTITEM(COMPONENT("x_out", list(), NONE()), NONE(), NONE()))), SOURCEINFO("/home/johti17/OpenModelica/OMCompiler/Examples/Circle.mo", false, 4, 3, 4, 13), NONE())), ELEMENTITEM(ELEMENT(false, NONE(), NOT_INNER_OUTER(), COMPONENTS(ATTR(false, false, NON_PARALLEL(), VAR(), BIDIR(), NONFIELD(), list()), TPATH(IDENT("Real"), NONE()), list(COMPONENTITEM(COMPONENT("y_out", list(), NONE()), NONE(), NONE()))), SOURCEINFO("/home/johti17/OpenModelica/OMCompiler/Examples/Circle.mo", false, 5, 3, 5, 13), NONE())), ELEMENTITEM(ELEMENT(false, NONE(), NOT_INNER_OUTER(), COMPONENTS(ATTR(false, false, NON_PARALLEL(), VAR(), BIDIR(), NONFIELD(), list()), TPATH(IDENT("Real"), NONE()), list(COMPONENTITEM(COMPONENT("x", list(), SOME(CLASSMOD(list(MODIFICATION(false, NON_EACH(), IDENT("start"), SOME(CLASSMOD(list(), EQMOD(REAL("0.1"), SOURCEINFO("/home/johti17/OpenModelica/OMCompiler/Examples/Circle.mo", false, 6, 15, 6, 19)))), NONE(), SOURCEINFO("/home/johti17/OpenModelica/OMCompiler/Examples/Circle.mo", false, 6, 10, 6, 19))), NOMOD()))), NONE(), NONE()))), SOURCEINFO("/home/johti17/OpenModelica/OMCompiler/Examples/Circle.mo", false, 6, 3, 6, 20), NONE())), ELEMENTITEM(ELEMENT(false, NONE(), NOT_INNER_OUTER(), COMPONENTS(ATTR(false, false, NON_PARALLEL(), VAR(), BIDIR(), NONFIELD(), list()), TPATH(IDENT("Real"), NONE()), list(COMPONENTITEM(COMPONENT("y", list(), SOME(CLASSMOD(list(MODIFICATION(false, NON_EACH(), IDENT("start"), SOME(CLASSMOD(list(), EQMOD(REAL("0.1"), SOURCEINFO("/home/johti17/OpenModelica/OMCompiler/Examples/Circle.mo", false, 7, 15, 7, 19)))), NONE(), SOURCEINFO("/home/johti17/OpenModelica/OMCompiler/Examples/Circle.mo", false, 7, 10, 7, 19))), NOMOD()))), NONE(), NONE()))), SOURCEINFO("/home/johti17/OpenModelica/OMCompiler/Examples/Circle.mo", false, 7, 3, 7, 20), NONE())))), EQUATIONS(list(EQUATIONITEM(EQ_EQUALS(CALL(CREF_IDENT("der", list()), FUNCTIONARGS(list(CREF(CREF_IDENT("x", list()))), list())), CREF(CREF_IDENT("y", list()))), NONE(), SOURCEINFO("/home/johti17/OpenModelica/OMCompiler/Examples/Circle.mo", false, 9, 3, 9, 13)), EQUATIONITEM(EQ_EQUALS(CALL(CREF_IDENT("der", list()), FUNCTIONARGS(list(CREF(CREF_IDENT("y", list()))), list())), CREF(CREF_IDENT("x", list()))), NONE(), SOURCEINFO("/home/johti17/OpenModelica/OMCompiler/Examples/Circle.mo", false, 10, 3, 10, 13)), EQUATIONITEM(EQ_EQUALS(CREF(CREF_IDENT("x_out", list())), CREF(CREF_IDENT("x", list()))), NONE(), SOURCEINFO("/home/johti17/OpenModelica/OMCompiler/Examples/Circle.mo", false, 11, 3, 11, 12)), EQUATIONITEM(EQ_EQUALS(CREF(CREF_IDENT("y_out", list())), CREF(CREF_IDENT("y", list()))), NONE(), SOURCEINFO("/home/johti17/OpenModelica/OMCompiler/Examples/Circle.mo", false, 12, 3, 12, 12))))), list(), NONE()), SOURCEINFO("/home/johti17/OpenModelica/OMCompiler/Examples/Circle.mo", false, 3, 1, 13, 11))), TOP())
  end
end

@testset "Create bouncing ball" begin
  @test_nothrow_nowarn begin PROGRAM(list(CLASS("BouncingBall", false, false ,false, R_MODEL(), PARTS(list(), list(), list(PUBLIC(list(ELEMENTITEM(ELEMENT(false, NONE(), NOT_INNER_OUTER(), COMPONENTS(ATTR(false, false, NON_PARALLEL(), PARAM(), BIDIR(), NONFIELD(), list()), TPATH(IDENT("Real"), NONE()), list(COMPONENTITEM(COMPONENT("e", list(), SOME(CLASSMOD(list(), EQMOD(REAL("0.7"), SOURCEINFO("/home/johti17/OpenModelica/OMCompiler/Examples/BouncingBall.mo", false, 2, 19, 2, 24))))), NONE(), SOME(COMMENT(SOME("coefficient of restitution"), NONE()))))), SOURCEINFO("/home/johti17/OpenModelica/OMCompiler/Examples/BouncingBall.mo", false, 2, 3, 2, 52), NONE())), ELEMENTITEM(ELEMENT(false, NONE(), NOT_INNER_OUTER(), COMPONENTS(ATTR(false, false, NON_PARALLEL(), PARAM(), BIDIR(), NONFIELD(), list()), TPATH(IDENT("Real"), NONE()), list(COMPONENTITEM(COMPONENT("g", list(), SOME(CLASSMOD(list(), EQMOD(REAL("9.81"), SOURCEINFO("/home/johti17/OpenModelica/OMCompiler/Examples/BouncingBall.mo", false, 3, 19, 3, 25))))), NONE(), SOME(COMMENT(SOME("gravity acceleration"), NONE()))))), SOURCEINFO("/home/johti17/OpenModelica/OMCompiler/Examples/BouncingBall.mo", false, 3, 3, 3, 47), NONE())), ELEMENTITEM(ELEMENT(false, NONE(), NOT_INNER_OUTER(), COMPONENTS(ATTR(false, false, NON_PARALLEL(), VAR(), BIDIR(), NONFIELD(), list()), TPATH(IDENT("Real"), NONE()), list(COMPONENTITEM(COMPONENT("h", list(), SOME(CLASSMOD(list(MODIFICATION(false, NON_EACH(), IDENT("fixed"), SOME(CLASSMOD(list(), EQMOD(BOOL(true), SOURCEINFO("/home/johti17/OpenModelica/OMCompiler/Examples/BouncingBall.mo", false, 4, 15, 4, 20)))), NONE(), SOURCEINFO("/home/johti17/OpenModelica/OMCompiler/Examples/BouncingBall.mo", false, 4, 10, 4, 20)), MODIFICATION(false, NON_EACH(), IDENT("start"), SOME(CLASSMOD(list(), EQMOD(INTEGER(1::ModelicaInteger), SOURCEINFO("/home/johti17/OpenModelica/OMCompiler/Examples/BouncingBall.mo", false, 4, 27, 4, 29)))), NONE(), SOURCEINFO("/home/johti17/OpenModelica/OMCompiler/Examples/BouncingBall.mo", false, 4, 22, 4, 29))), NOMOD()))), NONE(), SOME(COMMENT(SOME("height of ball"), NONE()))))), SOURCEINFO("/home/johti17/OpenModelica/OMCompiler/Examples/BouncingBall.mo", false, 4, 3, 4, 47), NONE())), ELEMENTITEM(ELEMENT(false, NONE(), NOT_INNER_OUTER(), COMPONENTS(ATTR(false, false, NON_PARALLEL(), VAR(), BIDIR(), NONFIELD(), list()), TPATH(IDENT("Real"), NONE()), list(COMPONENTITEM(COMPONENT("v", list(), SOME(CLASSMOD(list(MODIFICATION(false, NON_EACH(), IDENT("fixed"), SOME(CLASSMOD(list(), EQMOD(BOOL(true), SOURCEINFO("/home/johti17/OpenModelica/OMCompiler/Examples/BouncingBall.mo", false, 5, 15, 5, 20)))), NONE(), SOURCEINFO("/home/johti17/OpenModelica/OMCompiler/Examples/BouncingBall.mo", false, 5, 10, 5, 20))), NOMOD()))), NONE(), SOME(COMMENT(SOME("velocity of ball"), NONE()))))), SOURCEINFO("/home/johti17/OpenModelica/OMCompiler/Examples/BouncingBall.mo", false, 5, 3, 5, 40), NONE())), ELEMENTITEM(ELEMENT(false, NONE(), NOT_INNER_OUTER(), COMPONENTS(ATTR(false, false, NON_PARALLEL(), VAR(), BIDIR(), NONFIELD(), list()), TPATH(IDENT("Boolean"), NONE()), list(COMPONENTITEM(COMPONENT("flying", list(), SOME(CLASSMOD(list(MODIFICATION(false, NON_EACH(), IDENT("fixed"), SOME(CLASSMOD(list(), EQMOD(BOOL(true), SOURCEINFO("/home/johti17/OpenModelica/OMCompiler/Examples/BouncingBall.mo", false, 6, 23, 6, 28)))), NONE(), SOURCEINFO("/home/johti17/OpenModelica/OMCompiler/Examples/BouncingBall.mo", false, 6, 18, 6, 28)), MODIFICATION(false, NON_EACH(), IDENT("start"), SOME(CLASSMOD(list(), EQMOD(BOOL(true), SOURCEINFO("/home/johti17/OpenModelica/OMCompiler/Examples/BouncingBall.mo", false, 6, 35, 6, 40)))), NONE(), SOURCEINFO("/home/johti17/OpenModelica/OMCompiler/Examples/BouncingBall.mo", false, 6, 30, 6, 40))), NOMOD()))), NONE(), SOME(COMMENT(SOME("true, if ball is flying"), NONE()))))), SOURCEINFO("/home/johti17/OpenModelica/OMCompiler/Examples/BouncingBall.mo", false, 6, 3, 6, 67), NONE())), ELEMENTITEM(ELEMENT(false, NONE(), NOT_INNER_OUTER(), COMPONENTS(ATTR(false, false, NON_PARALLEL(), VAR(), BIDIR(), NONFIELD(), list()), TPATH(IDENT("Boolean"), NONE()), list(COMPONENTITEM(COMPONENT("impact", list(), NONE()), NONE(), NONE()))), SOURCEINFO("/home/johti17/OpenModelica/OMCompiler/Examples/BouncingBall.mo", false, 7, 3, 7, 17), NONE())), ELEMENTITEM(ELEMENT(false, NONE(), NOT_INNER_OUTER(), COMPONENTS(ATTR(false, false, NON_PARALLEL(), VAR(), BIDIR(), NONFIELD(), list()), TPATH(IDENT("Real"), NONE()), list(COMPONENTITEM(COMPONENT("v_new", list(), SOME(CLASSMOD(list(MODIFICATION(false, NON_EACH(), IDENT("fixed"), SOME(CLASSMOD(list(), EQMOD(BOOL(true), SOURCEINFO("/home/johti17/OpenModelica/OMCompiler/Examples/BouncingBall.mo", false, 8, 19, 8, 24)))), NONE(), SOURCEINFO("/home/johti17/OpenModelica/OMCompiler/Examples/BouncingBall.mo", false, 8, 14, 8, 24))), NOMOD()))), NONE(), NONE()))), SOURCEINFO("/home/johti17/OpenModelica/OMCompiler/Examples/BouncingBall.mo", false, 8, 3, 8, 25), NONE())), ELEMENTITEM(ELEMENT(false, NONE(), NOT_INNER_OUTER(), COMPONENTS(ATTR(false, false, NON_PARALLEL(), VAR(), BIDIR(), NONFIELD(), list()), TPATH(IDENT("Integer"), NONE()), list(COMPONENTITEM(COMPONENT("foo", list(), NONE()), NONE(), NONE()))), SOURCEINFO("/home/johti17/OpenModelica/OMCompiler/Examples/BouncingBall.mo", false, 9, 3, 9, 14), NONE())))), EQUATIONS(list(EQUATIONITEM(EQ_EQUALS(CREF(CREF_IDENT("impact", list())), RELATION(CREF(CREF_IDENT("h", list())), LESSEQ(), REAL("0.0"))), NONE(), SOURCEINFO("/home/johti17/OpenModelica/OMCompiler/Examples/BouncingBall.mo", false, 12, 3, 12, 20)), EQUATIONITEM(EQ_EQUALS(CREF(CREF_IDENT("foo", list())), IFEXP(CREF(CREF_IDENT("impact", list())), INTEGER(1::ModelicaInteger), INTEGER(2::ModelicaInteger), list())), NONE(), SOURCEINFO("/home/johti17/OpenModelica/OMCompiler/Examples/BouncingBall.mo", false, 13, 3, 13, 32)), EQUATIONITEM(EQ_EQUALS(CALL(CREF_IDENT("der", list()), FUNCTIONARGS(list(CREF(CREF_IDENT("v", list()))), list())), IFEXP(CREF(CREF_IDENT("flying", list())), UNARY(UMINUS(), CREF(CREF_IDENT("g", list()))), INTEGER(0::ModelicaInteger), list())), NONE(), SOURCEINFO("/home/johti17/OpenModelica/OMCompiler/Examples/BouncingBall.mo", false, 14, 3, 14, 36)), EQUATIONITEM(EQ_EQUALS(CALL(CREF_IDENT("der", list()), FUNCTIONARGS(list(CREF(CREF_IDENT("h", list()))), list())), CREF(CREF_IDENT("v", list()))), NONE(), SOURCEINFO("/home/johti17/OpenModelica/OMCompiler/Examples/BouncingBall.mo", false, 15, 3, 15, 13)), EQUATIONITEM(EQ_WHEN_E(ARRAY(list(LBINARY(RELATION(CREF(CREF_IDENT("h", list())), LESSEQ(), REAL("0.0")), AND(), RELATION(CREF(CREF_IDENT("v", list())), LESSEQ(), REAL("0.0"))), CREF(CREF_IDENT("impact", list())))), list(EQUATIONITEM(EQ_EQUALS(CREF(CREF_IDENT("v_new", list())), IFEXP(CALL(CREF_IDENT("edge", list()), FUNCTIONARGS(list(CREF(CREF_IDENT("impact", list()))), list())), UNARY(UMINUS(), BINARY(CREF(CREF_IDENT("e", list())), MUL(), CALL(CREF_IDENT("pre", list()), FUNCTIONARGS(list(CREF(CREF_IDENT("v", list()))), list())))), INTEGER(0::ModelicaInteger), list())), NONE(), SOURCEINFO("/home/johti17/OpenModelica/OMCompiler/Examples/BouncingBall.mo", false, 18, 5, 18, 50)), EQUATIONITEM(EQ_EQUALS(CREF(CREF_IDENT("flying", list())), RELATION(CREF(CREF_IDENT("v_new", list())), GREATER(), INTEGER(0::ModelicaInteger))), NONE(), SOURCEINFO("/home/johti17/OpenModelica/OMCompiler/Examples/BouncingBall.mo", false, 19, 5, 19, 23)), EQUATIONITEM(EQ_NORETCALL(CREF_IDENT("reinit", list()), FUNCTIONARGS(list(CREF(CREF_IDENT("v", list())), CREF(CREF_IDENT("v_new", list()))), list())), NONE(), SOURCEINFO("/home/johti17/OpenModelica/OMCompiler/Examples/BouncingBall.mo", false, 20, 5, 20, 21))),list()), NONE(), SOURCEINFO("/home/johti17/OpenModelica/OMCompiler/Examples/BouncingBall.mo", false, 17, 3, 21, 11))))), list(), NONE()), SOURCEINFO("/home/johti17/OpenModelica/OMCompiler/Examples/BouncingBall.mo", false, 1, 1, 23, 17))), TOP())
end

end #= End testset =#

end
