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
    include("helloWorld.jl")
  end
end #= End HelloWorld Init =#


@testset "Create Circle Model" begin
  @test_nothrow_nowarn begin
    include("circle.jl")
  end
end

@testset "Create bouncing ball" begin
  @test_nothrow_nowarn begin
    include("bouncingBall.jl")
end

@testset "Test matching on previous models" begin
end

end #= End testset =#

end
