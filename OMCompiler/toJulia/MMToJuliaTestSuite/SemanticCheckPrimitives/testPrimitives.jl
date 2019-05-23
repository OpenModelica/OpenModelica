@testset "Simple semantic tests" begin
r := RealTests.five();

print(String(r) + "=" + String(5) + "\n");

r := RealTests.minusFive();

print(String(r) + "=" + String(-5.0) + "\n");

r := RealTests.rAdd(1.5,1.4);

print(String(r) + "=" + String(2.9) + "\n");

r := RealTests.rMult(0.3,3);

print(String(r) + "=" + String(0.9) + "\n");

r := RealTests.rMult(4,-4);

print(String(r) + "=" + String(-16) + "\n");

r := RealTests.rMult(-4,-4);

print(String(r) + "=" + String(16) + "\n");

print("Before pow test\n");

r := RealTests.powTest(2.0,32);

print(String(2^32) + "==" + String(r) + "\n");

r := RealTests.rDiv(4,4);

print(String(r) + "=" + String(1) + "\n");

r := RealTests.rSub(1,1);

print(String(r) + "=" + String(0) + "\n");

r := RealTests.negateReal(-20);

print(String(r) + "=" + String(20) + "\n");

r := RealTests.branchTestReal(1);

print(String(r) + "=" + String(1) + "\n");

r := RealTests.branchTestReal(2);

print(String(r) + "=" + String(2) + "\n");

r := RealTests.branchTestReal(3);

print(String(r) + "=" + String(3) + "\n");

r := RealTests.branchTestReal(4);

print(String(r) + "=" + String(4) + "\n");

r := RealTests.branchTestReal(5);

print(String(r) + "=" + String(5) + "\n");

r := RealTests.absoluteVal1(-1);

print(String(r) + "=" + String(1) + "\n");

r := RealTests.absoluteVal2(0);

print(String(r) + "=" + String(0) + "\n");

r := RealTests.absoluteVal3(-999);

print(String(r) + "=" + String(999) + "\n");

r := RealTests.cosTest(1.8);

r := RealTests.checkGEQOperator(2,1);

print(String(r) + "=" + String(1) + "\n");

r := RealTests.checkLEQOperator(4,4);

print(String(r) + "=" + String(1) + "\n");

r := RealTests.checkGTOperator(5,4);

print(String(r) + "=" + String(1) + "\n");

r := RealTests.checkLTOperator(3,4);

print(String(r) + "=" + String(1) + "\n");

r := RealTests.checkEQOperator(1000,1000);

print(String(r) + "=" + String(1) + "\n");

r1 := RealTests.whileSum(20);

print(String(r1) + "=" + String(210) + "\n");

(r1,r2,r3) := RealTests.mReturnsReal(2,2,2);

(r1,r2,r3,r4) := RealTests.mReturnsReal2(2,2,2,2);

r := RealTests.whileSum(55);
r := IntegerTests.negativeOne();
r := IntegerTests.negativeOne();
getErrorString();
getErrorString();
r := IntegerTests.negativeOne();
getErrorString();
r := IntegerTests.leetLeet();
getErrorString();
r := IntegerTests.five();
r := IntegerTests.six();
print(String(r) + "=" + String(6) + "\n");
r := IntegerTests.leet();
print(String(r) + "=" + String(1337*8) + "\n");
r := IntegerTests.minusFive();
five := IntegerTests.five();
a := 3;
b := 5;
r := IntegerTests.iAdd(a,b);
getErrorString();
print(String(r) + "=" + String(8) + "\n");
print("Value of five:" + String(five) + "\n");
r := IntegerTests.iMult(4,4);
r := IntegerTests.iAdd(-9,1);
print("-8" + "="  + String(r));
r := IntegerTests.iMult(4,-4);
print(String(r) + "=" + String(-16) + "\n");
r := IntegerTests.iMult(-4,-4);
print(String(r) + "=" + String(16) + "\n");
r := IntegerTests.iDiv(4,4);
print(String(r) + "=" + String(1) + "\n");
r := IntegerTests.iSub(1000,-1000);
print(String(r) + "=" + String(2000) + "\n");
r := IntegerTests.negateInteger(-20);
print(String(r) + "=" + String(20) + "\n");
r := IntegerTests.branchTestInteger(1);
print(String(r) + "=" + String(1) + "\n");
r := IntegerTests.branchTestInteger(2);
print(String(r) + "=" + String(2) + "\n");
r := IntegerTests.branchTestInteger(3);
print(String(r) + "=" + String(3) + "\n");
r := IntegerTests.branchTestInteger(4);
print(String(r) + "=" + String(4) + "\n");
r := IntegerTests.branchTestInteger(5);
print(String(r) + "=" + String(5) + "\n");
r := IntegerTests.absoluteVal1(-1);
print(String(r) + "=" + String(1) + "\n");
r := IntegerTests.absoluteVal2(1);
print("absoluteVal2:" + String(r) + "=" + String(1) + "\n");
r := IntegerTests.absoluteVal3(-999);
print("absoluteVal3:" + String(r) + "=" + String(999) + "\n");
r := IntegerTests.checkGEQOperator(2,1);
print("GEQOPERATOR:" +String(r) + "=" + String(1) + "\n");
r := IntegerTests.checkLEQOperator(4,4);
print(String(r) + "=" + String(1) + "\n");
r := IntegerTests.checkGTOperator(5,4);
print(String(r) + "=" + String(1) + "\n");
r := IntegerTests.checkLTOperator(3,4);
print(String(r) + "=" + String(1) + "\n");
r := IntegerTests.checkEQOperator(1000,1000);
print(String(r) + "=" + String(1) + "\n");
(r1,r2,r3) := IntegerTests.callMReturnsInt(5,10,20);
(r1,r2,r3) := IntegerTests.mReturnsInt(5,10,20);
print("Value of r1 is:" + String(r1) +   "\tShould be:" + String(2*5) + "\n");
print("Value of r2 is:" + String(r2) +  "\tShould be:" + String(2*10) + "\n");
print("Value of r3 is:" + String(r3) +  "\tShould be:" + String(2*20) + "\n");
r := IntegerTests.whileSum(10);
getErrorString();
print(String(r) + "=" + String(55) + "\n");
r := IntegerTests.whileSum(r);
print(String(r) + "=" + "1540" + "\n");
r := IntegerTests.whileSum(r);
print(String(r) + "=" + "1186570" + "\n");
getErrorString();
r := BoolTests.returnTrue();

print(String(r) + "=" + "true\n");

r := BoolTests.notTest(false);

// print(String(r) + "=" + "true\n");

// r := BoolTests.orTest(false,true);

// print(String(r) + "=" + "true\n");

// r := BoolTests.andTest(true,true);

// print(String(r) + "=" + "true\n");

// r := BoolTests.ltTest(false,true);

// print(String(r) + "=" + "true\n");

// r := BoolTests.gtTest(true,false);

// print(String(r) + "=" + "true\n");

// r := BoolTests.leqTest(false,true);

// print(String(r) + "=" + "true");

// r := BoolTests.eqTest(true,true);

// print(String(r) + "=" + "true\n");

(r1,r2,r3) := BoolTests.mInverse(false,false,false);

print(String(r1) + ":shall be true\n" + String(r2) + ":shall be true\n" + String(r3) + ":shall be true\n");
end
