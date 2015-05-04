// name:     MatrixPow
// keywords: matrices,power
// status:   correct
//
// Test Matrix power
//

model MatrixPow
  Real m[3,3];
  Real m1[3,3];
  Real m0[3,3];
  parameter Real n[3,3] = ones(3,3);
equation
  m = n^2;
  m1 = n^1;
  m0 = n^0;
end MatrixPow;

// Result:
// class MatrixPow
//   Real m[1,1];
//   Real m[1,2];
//   Real m[1,3];
//   Real m[2,1];
//   Real m[2,2];
//   Real m[2,3];
//   Real m[3,1];
//   Real m[3,2];
//   Real m[3,3];
//   Real m1[1,1];
//   Real m1[1,2];
//   Real m1[1,3];
//   Real m1[2,1];
//   Real m1[2,2];
//   Real m1[2,3];
//   Real m1[3,1];
//   Real m1[3,2];
//   Real m1[3,3];
//   Real m0[1,1];
//   Real m0[1,2];
//   Real m0[1,3];
//   Real m0[2,1];
//   Real m0[2,2];
//   Real m0[2,3];
//   Real m0[3,1];
//   Real m0[3,2];
//   Real m0[3,3];
//   parameter Real n[1,1] = 1.0;
//   parameter Real n[1,2] = 1.0;
//   parameter Real n[1,3] = 1.0;
//   parameter Real n[2,1] = 1.0;
//   parameter Real n[2,2] = 1.0;
//   parameter Real n[2,3] = 1.0;
//   parameter Real n[3,1] = 1.0;
//   parameter Real n[3,2] = 1.0;
//   parameter Real n[3,3] = 1.0;
// equation
//   m[1,1] = n[1,1] ^ 2.0 + n[1,2] * n[2,1] + n[1,3] * n[3,1];
//   m[1,2] = n[1,2] * (n[1,1] + n[2,2]) + n[1,3] * n[3,2];
//   m[1,3] = n[1,1] * n[1,3] + n[1,2] * n[2,3] + n[1,3] * n[3,3];
//   m[2,1] = n[2,1] * (n[1,1] + n[2,2]) + n[2,3] * n[3,1];
//   m[2,2] = n[2,1] * n[1,2] + n[2,2] ^ 2.0 + n[2,3] * n[3,2];
//   m[2,3] = n[2,1] * n[1,3] + n[2,2] * n[2,3] + n[2,3] * n[3,3];
//   m[3,1] = n[3,1] * n[1,1] + n[3,2] * n[2,1] + n[3,3] * n[3,1];
//   m[3,2] = n[3,1] * n[1,2] + n[3,2] * n[2,2] + n[3,3] * n[3,2];
//   m[3,3] = n[3,1] * n[1,3] + n[3,2] * n[2,3] + n[3,3] ^ 2.0;
//   m1[1,1] = n[1,1];
//   m1[1,2] = n[1,2];
//   m1[1,3] = n[1,3];
//   m1[2,1] = n[2,1];
//   m1[2,2] = n[2,2];
//   m1[2,3] = n[2,3];
//   m1[3,1] = n[3,1];
//   m1[3,2] = n[3,2];
//   m1[3,3] = n[3,3];
//   m0[1,1] = 1.0;
//   m0[1,2] = 0.0;
//   m0[1,3] = 0.0;
//   m0[2,1] = 0.0;
//   m0[2,2] = 1.0;
//   m0[2,3] = 0.0;
//   m0[3,1] = 0.0;
//   m0[3,2] = 0.0;
//   m0[3,3] = 1.0;
// end MatrixPow;
// endResult
