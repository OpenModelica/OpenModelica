// name:     NthRoot1
// keywords: builtin
// status:   correct
//
// Test builtin function nthRoot.
//

model NthRoot1
  Real x;
equation
  x = nthRoot(4, 2);
  x = nthRoot(4, 3);
  x = nthRoot(-4, 3);
  x = nthRoot(x, 3);
end NthRoot1;

// Result:
// class NthRoot1
//   Real x;
// equation
//   x = 2.0;
//   x = 1.5874010519681994;
//   x = -1.5874010519681994;
//   x = nthRoot(x, 3);
// end NthRoot1;
// endResult
