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
  #= TODO. Tests=#
end #= End testset =#

end
