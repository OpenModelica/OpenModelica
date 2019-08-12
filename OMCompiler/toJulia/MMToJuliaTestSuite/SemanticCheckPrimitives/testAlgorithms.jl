
module TestAlgorithms
#= We might fail here already =#
include("../OutputAlgorithms/Algorithms.jl")
include("../testsuiteUtil.jl")
using Test
using .Algorithms
using .MMToJuliaTestSuiteUtil
import Random
using Random
using MetaModelica

@testset "Test Algorithms" begin
  @test_nothrow_nowarn Algorithms.factorial(5) == 120
  @test_nothrow_nowarn Algorithms.ackerman(1, 2) == 4
  @test_nothrow_nowarn Algorithms.realSummation() == 32000000
  @test_nothrow_nowarn Algorithms.fibonacci(10) == 55
  @test_nothrow_nowarn Algorithms.tak(5,5,5) == 5
  @test_nothrow_nowarn length(Algorithms.createTestArray2(10)) == 10
  #= Attempting to use the builtin merge sort =#
  @test_nothrow_nowarn length(Algorithms.sort(list(), intGt)) == 0
  @test_nothrow_nowarn 1 == length(Algorithms.sort(list(1), intGt))
  testLst = list(randperm(100)...)
  @test_nothrow_nowarn 100 == length(Algorithms.sort(testLst, intGt))
  @test_nothrow_nowarn 1 == listHead(Algorithms.sort(testLst, intGt))
  testLst = list(randperm(20000)...)
  #@time Algorithms.sort(testLst)
end #= End testset =#

end
