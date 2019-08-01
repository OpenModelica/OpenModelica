module TestIntegerSemantics
#= We might fail here already =#
include("../OutputPrimitives/IntegerTests.jl")
include("../testsuiteUtil.jl")
using Test
using .IntegerTests
using .MMToJuliaTestSuiteUtil

@testset "Test Integer semantics" begin

@test_nothrow_nowarn_test IntegerTests.negativeOne() == -1
@test_nothrow_nowarn_test IntegerTests.five() == 5
@test_nothrow_nowarn_test IntegerTests.leet() == 1337 * 8
@test_nothrow_nowarn_test IntegerTests.leetLeet() == IntegerTests.leet()
@test_nothrow_nowarn_test IntegerTests.iAdd(4, 4) == 8
@test_nothrow_nowarn_test IntegerTests.iMult(4, 4) == 16
@test_nothrow_nowarn_test IntegerTests.iSub(4, 4) == 0
@test_nothrow_nowarn_test IntegerTests.negateInteger(4) == -4
@test_nothrow_nowarn_test IntegerTests.branchTestInteger(1) == 1
@test_nothrow_nowarn_test IntegerTests.branchTestInteger(2) == 2
@test_nothrow_nowarn_test IntegerTests.branchTestInteger(3) == 3
@test_nothrow_nowarn_test IntegerTests.branchTestInteger(4) == 4
@test_nothrow_nowarn_test IntegerTests.branchTestInteger(5) == 5
@test_nothrow_nowarn_test IntegerTests.integerArithmeticTest(3) == 9
@test_nothrow_nowarn_test IntegerTests.integerArithmeticTest2(3) == 9
@test_nothrow_nowarn_test IntegerTests.absoluteVal1(-4) == 4
@test_nothrow_nowarn_test IntegerTests.absoluteVal2(-8) == 8

end
end
