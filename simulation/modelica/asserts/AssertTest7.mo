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
    assert(x >= 0.5, "Variable x(=" + String(x) +") out of limit");
    y := 1;
    print("Value of x(=" + String(x) +")\n");
  end f;
  Real x(start=1);
  Real y;
equation
  der(x) = -y;
  y = if x<0.51 then f(x) else 1;
equation
end AssertTest;

class Test7
  AssertTest assertTest;
end Test7;

// Result:
// function AssertTest.f
//   input Real x;
//   output Real y;
// algorithm
//   assert(x >= 0.5, "Variable x(=" + String(x, 0, true, 6) + ") out of limit");
//   y := 1.0;
//   AssertTest.print("Value of x(=" + String(x, 0, true, 6) + ")
// ");
// end AssertTest.f;
//
// function AssertTest.print "Print string to terminal or file"
//   input String string = "" "String to be printed";
//
//   external "C" myPuts(string);
// end AssertTest.print;
//
// class Test7
//   Real assertTest.x(start = 1.0);
//   Real assertTest.y;
// equation
//   der(assertTest.x) = -assertTest.y;
//   assertTest.y = if assertTest.x < 0.49 then -AssertTest.f(assertTest.x) else AssertTest.f(assertTest.x);
// end Test7;
// endResult
