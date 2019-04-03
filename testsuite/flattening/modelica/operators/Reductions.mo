// name:     Reductions
// keywords: reductions
// status:   correct
//
// Tests flattening of non-constant reductions.
//

model Reductions
  parameter Integer n = 5;
  Real A[n];
  Real B[n];
  Real c;
  Real d;
  Real e;
  Real f;
  Real g[n,n];
  Real h;
equation
  c = sum(A[i]^2 + B[i]^2 for i in 1:n);
  d = product(A[i]^2 + B[i]^2 for i in 1:n);
  e = max(A[i]^2 + B[i]^2 for i in 1:n);
  f = min(A[i]^2 + B[i]^2 for i in 1:n);
  g = {(1/(i+j-1)) for i in 1:n, j in 1:n};
  h = sum((1/(i+j-1)) for i in 1:n, j in 1:n);
end Reductions;

// Result:
// class Reductions
//   parameter Integer n = 5;
//   Real A[1];
//   Real A[2];
//   Real A[3];
//   Real A[4];
//   Real A[5];
//   Real B[1];
//   Real B[2];
//   Real B[3];
//   Real B[4];
//   Real B[5];
//   Real c;
//   Real d;
//   Real e;
//   Real f;
//   Real g[1,1];
//   Real g[1,2];
//   Real g[1,3];
//   Real g[1,4];
//   Real g[1,5];
//   Real g[2,1];
//   Real g[2,2];
//   Real g[2,3];
//   Real g[2,4];
//   Real g[2,5];
//   Real g[3,1];
//   Real g[3,2];
//   Real g[3,3];
//   Real g[3,4];
//   Real g[3,5];
//   Real g[4,1];
//   Real g[4,2];
//   Real g[4,3];
//   Real g[4,4];
//   Real g[4,5];
//   Real g[5,1];
//   Real g[5,2];
//   Real g[5,3];
//   Real g[5,4];
//   Real g[5,5];
//   Real h;
// equation
//   c = A[1] ^ 2.0 + B[1] ^ 2.0 + A[2] ^ 2.0 + B[2] ^ 2.0 + A[3] ^ 2.0 + B[3] ^ 2.0 + A[4] ^ 2.0 + B[4] ^ 2.0 + A[5] ^ 2.0 + B[5] ^ 2.0;
//   d = (A[1] ^ 2.0 + B[1] ^ 2.0) * (A[2] ^ 2.0 + B[2] ^ 2.0) * (A[3] ^ 2.0 + B[3] ^ 2.0) * (A[4] ^ 2.0 + B[4] ^ 2.0) * (A[5] ^ 2.0 + B[5] ^ 2.0);
//   e = max({A[1] ^ 2.0 + B[1] ^ 2.0, A[2] ^ 2.0 + B[2] ^ 2.0, A[3] ^ 2.0 + B[3] ^ 2.0, A[4] ^ 2.0 + B[4] ^ 2.0, A[5] ^ 2.0 + B[5] ^ 2.0});
//   f = min({A[1] ^ 2.0 + B[1] ^ 2.0, A[2] ^ 2.0 + B[2] ^ 2.0, A[3] ^ 2.0 + B[3] ^ 2.0, A[4] ^ 2.0 + B[4] ^ 2.0, A[5] ^ 2.0 + B[5] ^ 2.0});
//   g[1,1] = 1.0;
//   g[1,2] = 0.5;
//   g[1,3] = 0.3333333333333333;
//   g[1,4] = 0.25;
//   g[1,5] = 0.2;
//   g[2,1] = 0.5;
//   g[2,2] = 0.3333333333333333;
//   g[2,3] = 0.25;
//   g[2,4] = 0.2;
//   g[2,5] = 0.1666666666666667;
//   g[3,1] = 0.3333333333333333;
//   g[3,2] = 0.25;
//   g[3,3] = 0.2;
//   g[3,4] = 0.1666666666666667;
//   g[3,5] = 0.1428571428571428;
//   g[4,1] = 0.25;
//   g[4,2] = 0.2;
//   g[4,3] = 0.1666666666666667;
//   g[4,4] = 0.1428571428571428;
//   g[4,5] = 0.125;
//   g[5,1] = 0.2;
//   g[5,2] = 0.1666666666666667;
//   g[5,3] = 0.1428571428571428;
//   g[5,4] = 0.125;
//   g[5,5] = 0.1111111111111111;
//   h = 6.456349206349207;
// end Reductions;
// endResult
