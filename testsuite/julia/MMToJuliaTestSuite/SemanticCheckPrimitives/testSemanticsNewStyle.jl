using Main
using ExportAll
  include("../OutputNewStyle/NewStyle.jl")
@exportAll
module TestNewStyle

#=Make a macro that searches? mImport (It checks main before checking other modules) =#

using Test
import Main.TestPackage
@info LOAD_PATH
@info names(Main)
@testset "Testing New MM style" begin
  @test true == true
  @info TestPackage.test()
end

end
