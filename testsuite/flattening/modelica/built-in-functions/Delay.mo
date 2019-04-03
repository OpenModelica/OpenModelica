// name:     Delay
// keywords: builtin
// status:   correct
//
// Test builtin function delay.
//

model Delay
  Real x, y, z;
equation
  y = sin(time);
  x = delay(y+1, 2.5);
  z = delay(y-1, 0.5, 1.0);
end Delay;

// Result:
// class Delay
//   Real x;
//   Real y;
//   Real z;
// equation
//   y = sin(time);
//   x = 1.0 + delay(y, 2.5, 2.5);
//   z = -1.0 + delay(y, 0.5, 1.0);
// end Delay;
// endResult
