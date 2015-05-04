// name: Linspace1
// keywords: linspace bug2027
// status: correct
//
// Tests the built-in linspace function.
//

model Linspace1
  Real x[2];
  parameter Real a = 0;
  parameter Real b = 1;
equation
  x = linspace(a, b, 2);
end Linspace1;

// Result:
// class Linspace1
//   Real x[1];
//   Real x[2];
//   parameter Real a = 0.0;
//   parameter Real b = 1.0;
// equation
//   x[1] = a;
//   x[2] = a + b - a;
// end Linspace1;
// endResult
