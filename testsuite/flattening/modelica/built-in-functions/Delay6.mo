// name:     Delay6
// keywords: builtin
// status:   correct
//
// Test flattening of the builtin function delay.
//

model Delay
  Real x, y;
  Real a = 1.0;
  constant Real b=2.0;
equation
  x = sin(time);
  y = delay(x, a, b);
end Delay;

// Result:
// class Delay
//   Real x;
//   Real y;
//   Real a = 1.0;
//   constant Real b = 2.0;
// equation
//   x = sin(time);
//   y = delay(x, a, 2.0);
// end Delay;
// endResult
