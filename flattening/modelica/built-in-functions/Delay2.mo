// name:     Delay2
// keywords: builtin
// status:   correct
//
// Test flattening of the builtin function delay.
// Expression value is cast into Real.
//

model Delay
  Real x;
  Integer y;
equation
  y = 0;
  x = delay(y+1, 2.5);
end Delay;

// Result:
// class Delay
//   Real x;
//   Integer y;
// equation
//   y = 0;
//   x = delay(/*Real*/(1 + y), 2.5, 2.5);
// end Delay;
// endResult
