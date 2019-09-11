module testBooleanSemantics
#= We might fail here already =#
include("../OutputPrimitives/BoolTests.jl")
include("../testsuiteUtil.jl")

using Test
using .BoolTests
using .MMToJuliaTestSuiteUtil

@testset "Test Boolean semantics" begin

  @test_nothrow_nowarn_test BoolTests.returnTrue() == true
  @test_nothrow_nowarn_test BoolTests.notTest(true) == false
  @test_nothrow_nowarn_test BoolTests.orTest(true, false) == true
  @test_nothrow_nowarn_test BoolTests.andTest(false, true) == false
  @test_nothrow_nowarn_test BoolTests.ltTest(true, false) == false
  @test_nothrow_nowarn_test BoolTests.gtTest(true, false) == true
  @test_nothrow_nowarn_test BoolTests.geqTest(true, false) == true
  @test_nothrow_nowarn_test BoolTests.leqTest(true, false) == false
  @test_nothrow_nowarn_test BoolTests.eqTest(true, true) == true
  @test_nothrow_nowarn_test BoolTests.booleanBranching(true) == true
  @test_nothrow_nowarn_test BoolTests.booleanBranching(false) == false
  @test_nothrow_nowarn_test BoolTests.mInverse(true, true, true) == (false, false, false)

end
end
