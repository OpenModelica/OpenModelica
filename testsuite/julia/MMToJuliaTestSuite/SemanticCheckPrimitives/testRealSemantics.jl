module testRealSemantics
#= We might fail here already =#
include("../OutputPrimitives/RealTests.jl")
include("../testsuiteUtil.jl")
using Test
using .RealTests
using .MMToJuliaTestSuiteUtil

@testset "Test Real semantics" begin

@test_nothrow_nowarn_test RealTests.five() == 5.
@test_nothrow_nowarn_test RealTests.rAdd(4., 4.) == 8.
@test_nothrow_nowarn_test RealTests.rMult(4., 4.) == 16.
@test_nothrow_nowarn_test RealTests.rSub(4., 4.) == 0.
@test_nothrow_nowarn_test RealTests.negateReal(4.) == -4.
@test_nothrow_nowarn_test RealTests.branchTestReal(1.) == 1.
@test_nothrow_nowarn_test RealTests.branchTestReal(2.) == 2.
@test_nothrow_nowarn_test RealTests.branchTestReal(3.) == 3.
@test_nothrow_nowarn_test RealTests.branchTestReal(4.) == 4.
@test_nothrow_nowarn_test RealTests.branchTestReal(5.) == 5.
@test_nothrow_nowarn_test RealTests.realArithmeticTest(3.) == 9.
@test_nothrow_nowarn_test RealTests.realArithmeticTest2(3.) == 9.
@test_nothrow_nowarn_test RealTests.absoluteVal1(-4.) == 4.
@test_nothrow_nowarn_test RealTests.absoluteVal2(-8.) == 8.

end

end
