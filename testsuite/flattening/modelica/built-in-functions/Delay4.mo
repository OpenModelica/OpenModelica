// name:     Delay4
// keywords: builtin
// status:   correct
//
// Test flattening of the builtin function delay.
// Use of a parameter variable for the delay.
//

model Delay
  Real x, y;
  parameter Real a=1.0;
equation
  a = 1.0;
  x = sin(time);
  y = delay(x, a);
end Delay;

// Result:
// class Delay
//   Real x;
//   Real y;
//   parameter Real a = 1.0;
// equation
//   a = 1.0;
//   x = sin(time);
//   y = delay(x, a, a);
// end Delay;
// endResult
