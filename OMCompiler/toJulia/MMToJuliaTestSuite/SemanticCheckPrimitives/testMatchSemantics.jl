#= TODO add models as includes=#
module TestMatch
#= We might fail here already =#
include("../OutputMatchExpressions/MatchExpressions.jl")
include("../testsuiteUtil.jl")
using Test
import Absyn
using .MatchExpressions
using .MMToJuliaTestSuiteUtil
using MetaModelica


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

  #= Try to instantiate parts of Model M =#
  @test_nothrow_nowarn begin
    Absyn.PARTS(list(Absyn.PUBLIC(list())), list(), list(), list(), NONE())
  end

end

end #= End testset =#
