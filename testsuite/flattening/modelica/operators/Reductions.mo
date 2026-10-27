// name:     Reductions
// keywords: reductions
// status:   correct
//
// Tests flattening of reductions.
//

model Reductions
  constant Integer n = 5;
  Real A[n];
  Real B[n];
  Real c;
  Real d;
  constant Real C[n] = {1, 2, 3, 4, 5};
  constant Real e = max(C[i]^2 for i in 1:n);
  constant Real f = min(C[i]^2 for i in 1:n);
  constant Real g[n,n] = {(1/(i+j-1)) for i in 1:n, j in 1:n};
  Real h;
  Real k;
equation
  c = sum(A[i]^2 + B[i]^2 for i in 1:n);
  d = product(A[i]^2 + B[i]^2 for i in 1:n);
  h = sum((1/(i+j-1)) for i in 1:n, j in 1:n);
  k = .sum(i for i in 1:n);
end Reductions;

// Result:
// class Reductions
//   constant Integer n = 5;
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
//   constant Real C[1] = 1.0;
//   constant Real C[2] = 2.0;
//   constant Real C[3] = 3.0;
//   constant Real C[4] = 4.0;
//   constant Real C[5] = 5.0;
//   constant Real e = 25.0;
//   constant Real f = 1.0;
//   constant Real g[1,1] = 1.0;
//   constant Real g[1,2] = 0.5;
//   constant Real g[1,3] = 0.3333333333333333;
//   constant Real g[1,4] = 0.25;
//   constant Real g[1,5] = 0.2;
//   constant Real g[2,1] = 0.5;
//   constant Real g[2,2] = 0.3333333333333333;
//   constant Real g[2,3] = 0.25;
//   constant Real g[2,4] = 0.2;
//   constant Real g[2,5] = 0.16666666666666666;
//   constant Real g[3,1] = 0.3333333333333333;
//   constant Real g[3,2] = 0.25;
//   constant Real g[3,3] = 0.2;
//   constant Real g[3,4] = 0.16666666666666666;
//   constant Real g[3,5] = 0.14285714285714285;
//   constant Real g[4,1] = 0.25;
//   constant Real g[4,2] = 0.2;
//   constant Real g[4,3] = 0.16666666666666666;
//   constant Real g[4,4] = 0.14285714285714285;
//   constant Real g[4,5] = 0.125;
//   constant Real g[5,1] = 0.2;
//   constant Real g[5,2] = 0.16666666666666666;
//   constant Real g[5,3] = 0.14285714285714285;
//   constant Real g[5,4] = 0.125;
//   constant Real g[5,5] = 0.1111111111111111;
//   Real h;
//   Real k;
// equation
//   c = A[1] ^ 2.0 + B[1] ^ 2.0 + A[2] ^ 2.0 + B[2] ^ 2.0 + A[3] ^ 2.0 + B[3] ^ 2.0 + A[4] ^ 2.0 + B[4] ^ 2.0 + A[5] ^ 2.0 + B[5] ^ 2.0;
//   d = (A[1] ^ 2.0 + B[1] ^ 2.0) * (A[2] ^ 2.0 + B[2] ^ 2.0) * (A[3] ^ 2.0 + B[3] ^ 2.0) * (A[4] ^ 2.0 + B[4] ^ 2.0) * (A[5] ^ 2.0 + B[5] ^ 2.0);
//   h = 6.456349206349208;
//   k = 15.0;
// end Reductions;
// endResult
