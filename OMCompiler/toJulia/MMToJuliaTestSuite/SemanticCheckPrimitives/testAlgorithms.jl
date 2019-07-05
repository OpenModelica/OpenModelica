#= TODO add docstring=#
module TestAlgorithms
#= We might fail here already =#
include("../OutputAlgorithms/Algorithms.jl")
include("../testsuiteUtil.jl")
#include("./tableu.jl") For simplex
using Test
using .Algorithms
using .MMToJuliaTestSuiteUtil

@testset "Test Algorithms" begin
  @test_nothrow_nowarn Algorithms.factorial(5) == 120
  @test_nothrow_nowarn Algorithms.ackerman(1, 2) == 4
  @test_nothrow_nowarn Algorithms.realSummation() == 32000000
  @test_nothrow_nowarn Algorithms.fibonacci(10) == 55
end #= End testset =#

end
