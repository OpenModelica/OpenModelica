// name: Abs
// keywords: abs
// status: correct
//
// Testing the built-in abs function
//

model Abs
  Real r1, r2;
equation
  r1 = abs(100);
  r2 = abs(-100);
end Abs;

// Result:
// class Abs
//   Real r1;
//   Real r2;
// equation
//   r1 = 100.0;
//   r2 = 100.0;
// end Abs;
// endResult
