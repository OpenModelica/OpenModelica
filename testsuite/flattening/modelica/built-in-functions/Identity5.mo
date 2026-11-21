// name: Identity5
// keywords: identity, cast
// status: correct
//
// identity in a Real context evaluates to a Real matrix, see #18074.
//

model Identity5
  parameter Integer n = 2;
  Real a[n, n] = identity(n);
  Real b[n, n] = time*identity(n);
  Real c[2, 2];
equation
  c = identity(2);
end Identity5;

// Result:
// class Identity5
//   final parameter Integer n = 2;
//   Real a[1,1];
//   Real a[1,2];
//   Real a[2,1];
//   Real a[2,2];
//   Real b[1,1];
//   Real b[1,2];
//   Real b[2,1];
//   Real b[2,2];
//   Real c[1,1];
//   Real c[1,2];
//   Real c[2,1];
//   Real c[2,2];
// equation
//   a = {{1.0, 0.0}, {0.0, 1.0}};
//   b = {{time, 0.0}, {0.0, time}};
//   c[1,1] = 1.0;
//   c[1,2] = 0.0;
//   c[2,1] = 0.0;
//   c[2,2] = 1.0;
// end Identity5;
// endResult
