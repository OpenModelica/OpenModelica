// name:     AssertTest
// keywords: assert
// status:   correct
//
// Drmodelica: 8.2 Assert (p. 249)
//


class AssertTest
  parameter Real lowlimit   = -5;
  parameter Real highlimit   =  5;
  parameter Real x = 7;
equation
  assert(x >= lowlimit and x <= highlimit, "Variable x out of limit");
end AssertTest;

class AssertTestInst
  AssertTest assertTest(lowlimit = -2, highlimit = 6, x = 5);
end AssertTestInst;

// Result:
// class AssertTestInst
//   parameter Real assertTest.lowlimit = -2.0;
//   parameter Real assertTest.highlimit = 6.0;
//   parameter Real assertTest.x = 5.0;
// equation
//   assert(assertTest.x >= assertTest.lowlimit and assertTest.x <= assertTest.highlimit, "Variable x out of limit");
// end AssertTestInst;
// [flattening/modelica/asserts/AssertTest.mo:10:3-10:33:writable] Warning: Components are deprecated in class.
// [flattening/modelica/asserts/AssertTest.mo:11:3-11:34:writable] Warning: Components are deprecated in class.
// [flattening/modelica/asserts/AssertTest.mo:12:3-12:23:writable] Warning: Components are deprecated in class.
// [flattening/modelica/asserts/AssertTest.mo:14:3-14:70:writable] Warning: Equation sections are deprecated in class.
// [flattening/modelica/asserts/AssertTest.mo:18:3-18:61:writable] Warning: Components are deprecated in class.
//
// endResult
