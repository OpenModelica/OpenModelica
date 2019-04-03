// name:     Matrix2
// keywords: array, matrices, matrix, bug2033
// status:   correct
//
// Tests the builtin matrix operator.
//

model Matrix2
  parameter Integer M=5;
  parameter Real a[M] = zeros(M);
  Real b[M, 1];
equation
  b = matrix(a);
end Matrix2;

// Result:
// class Matrix2
//   parameter Integer M = 5;
//   parameter Real a[1] = 0.0;
//   parameter Real a[2] = 0.0;
//   parameter Real a[3] = 0.0;
//   parameter Real a[4] = 0.0;
//   parameter Real a[5] = 0.0;
//   Real b[1,1];
//   Real b[2,1];
//   Real b[3,1];
//   Real b[4,1];
//   Real b[5,1];
// equation
//   b[1,1] = a[1];
//   b[2,1] = a[2];
//   b[3,1] = a[3];
//   b[4,1] = a[4];
//   b[5,1] = a[5];
// end Matrix2;
// endResult
