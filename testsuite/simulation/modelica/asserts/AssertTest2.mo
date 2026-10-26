// name:     AssertTest2
// keywords: assert
// status:   correct
//
// Drmodelica: 9.1 assert (p. 298)
//

class AssertTest
  parameter Real lowlimit;
  parameter Real highlimit;
  Real x = 5;
equation
  assert(x >= lowlimit and x <= highlimit, "Variable x out of limit");
end AssertTest;

class Test2
  AssertTest assertTest(lowlimit = 6, highlimit = 20);
end Test2;

// Result:
// class Test2
//   parameter Real assertTest.lowlimit = 6.0;
//   parameter Real assertTest.highlimit = 20.0;
//   Real assertTest.x = 5.0;
// equation
//   assert(assertTest.x >= assertTest.lowlimit and assertTest.x <= assertTest.highlimit,"Variable x out of limit");
// end Test2;
// endResult
