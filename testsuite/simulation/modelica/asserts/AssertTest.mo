// name:     AssertTest
// keywords: assert
// status:   correct
//
// Drmodelica: 8.2 Assert (p. 249)
//

class AssertTest
  parameter Real lowlimit   = -5;
  parameter Real highlimit   =  5;
  Real x = 7;
equation
  assert(x >= lowlimit and x <= highlimit, "Variable x out of limit");
end AssertTest;

class AssertTestInst
  AssertTest assertTest(lowlimit = -2, highlimit = 6);
end AssertTestInst;

class AssertTestDuringInst
equation
  assert(false, "Testing assert during instantiation");
end AssertTestDuringInst;

// class AssertTestInst
// parameter Real assertTest.lowlimit = -2;
// parameter Real assertTest.highlimit = 6;
// parameter Real assertTest.x = 5;
// equation
// assert(assertTest.x >= assertTest.lowlimit AND assertTest.x <= assertTest.highlimit,"Variable x out of limit");
// end AssertTestInst;// Result:
// class AssertTestDuringInst
// equation
//   assert(false,"Testing assert during instantiation");
// end AssertTestDuringInst;
// endResult
