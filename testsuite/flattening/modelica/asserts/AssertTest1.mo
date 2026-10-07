// name:     AssertTest1
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

class Test1
  AssertTest assertTest(lowlimit = 4, highlimit = 8);
end Test1;

// Result:
// class Test1
//   parameter Real assertTest.lowlimit = 4.0;
//   parameter Real assertTest.highlimit = 8.0;
//   Real assertTest.x = 5.0;
// equation
//   assert(assertTest.x >= assertTest.lowlimit and assertTest.x <= assertTest.highlimit, "Variable x out of limit");
// end Test1;
// [flattening/modelica/asserts/AssertTest1.mo:9:3-9:26:writable] Warning: Components are deprecated in class.
// [flattening/modelica/asserts/AssertTest1.mo:10:3-10:27:writable] Warning: Components are deprecated in class.
// [flattening/modelica/asserts/AssertTest1.mo:11:3-11:13:writable] Warning: Components are deprecated in class.
// [flattening/modelica/asserts/AssertTest1.mo:13:3-13:70:writable] Warning: Equation sections are deprecated in class.
// [flattening/modelica/asserts/AssertTest1.mo:17:3-17:53:writable] Warning: Components are deprecated in class.
//
// endResult
