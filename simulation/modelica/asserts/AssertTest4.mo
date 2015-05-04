// name:     AssertTest4
// keywords: assert
// status:   correct
//
//


class AssertTest
  function print "Print string to terminal or file"
    input String string="" "String to be printed";
    external "C" myPuts(string) annotation(Include="#define myPuts(X) { fputs(X,stdout); fflush(NULL); }");
  end print;
  function f
    input Real x;
    output Real y;
  algorithm
    y := x;
    print("Value of x(=" + String(x) +")\n");
  end f;
  Real x(start=1);
  Real y;
equation
  x = 1-time;
  y = f(x);
  assert(x >= 0.5, "Variable x(=" + String(x) +") out of limit");
equation
end AssertTest;

class Test4
  AssertTest assertTest;
end Test4;

// Result:
// function AssertTest.f
//   input Real x;
//   output Real y;
// algorithm
//   y := x;
//   AssertTest.print("Value of x(=" + String(x, 0, true, 6) + ")
//   ");
// end AssertTest.f;
//
// function AssertTest.print "Print string to terminal or file"
//   input String string = "" "String to be printed";
//
//   external "C" myPuts(string);
// end AssertTest.print;
//
// class Test4
//   Real assertTest.x(start = 1.0);
//   Real assertTest.y;
// equation
//   assertTest.x = 1.0 - time;
//   assertTest.y = AssertTest.f(assertTest.x);
//   assert(assertTest.x >= 0.5, "Variable x(=" + String(assertTest.x, 0, true, 6) + ") out of limit");
// end Test4;
// endResult
