// name:     MatrixAddition
// keywords: matrix addition simplify
// status:   correct
//
// Tests simplification of matrix addition.
//

model MatrixAddition
 Real[3] M;
 Real[3,3] N;
 Real[3,3] K;
 parameter Real[3] A= {1,2,3};
 parameter Real[3, 3] B= {{1,2,3},{4,5,6},{7,8,9}};
 parameter Real[3, 3] C= {{1,2,3},{4,5,6},{7,8,9}};
 parameter Real[3] D= {1,2,3};
equation
 M = A+(B+C*C)*D;
 N = C+B;
 K = C-B;
end MatrixAddition;


// Result:
// class MatrixAddition
//   Real M[1];
//   Real M[2];
//   Real M[3];
//   Real N[1,1];
//   Real N[1,2];
//   Real N[1,3];
//   Real N[2,1];
//   Real N[2,2];
//   Real N[2,3];
//   Real N[3,1];
//   Real N[3,2];
//   Real N[3,3];
//   Real K[1,1];
//   Real K[1,2];
//   Real K[1,3];
//   Real K[2,1];
//   Real K[2,2];
//   Real K[2,3];
//   Real K[3,1];
//   Real K[3,2];
//   Real K[3,3];
//   parameter Real A[1] = 1.0;
//   parameter Real A[2] = 2.0;
//   parameter Real A[3] = 3.0;
//   parameter Real B[1,1] = 1.0;
//   parameter Real B[1,2] = 2.0;
//   parameter Real B[1,3] = 3.0;
//   parameter Real B[2,1] = 4.0;
//   parameter Real B[2,2] = 5.0;
//   parameter Real B[2,3] = 6.0;
//   parameter Real B[3,1] = 7.0;
//   parameter Real B[3,2] = 8.0;
//   parameter Real B[3,3] = 9.0;
//   parameter Real C[1,1] = 1.0;
//   parameter Real C[1,2] = 2.0;
//   parameter Real C[1,3] = 3.0;
//   parameter Real C[2,1] = 4.0;
//   parameter Real C[2,2] = 5.0;
//   parameter Real C[2,3] = 6.0;
//   parameter Real C[3,1] = 7.0;
//   parameter Real C[3,2] = 8.0;
//   parameter Real C[3,3] = 9.0;
//   parameter Real D[1] = 1.0;
//   parameter Real D[2] = 2.0;
//   parameter Real D[3] = 3.0;
// equation
//   M[1] = A[1] + (B[1,1] + C[1,1] ^ 2.0 + C[1,2] * C[2,1] + C[1,3] * C[3,1]) * D[1] + (B[1,2] + C[1,2] * (C[1,1] + C[2,2]) + C[1,3] * C[3,2]) * D[2] + (B[1,3] + C[1,1] * C[1,3] + C[1,2] * C[2,3] + C[1,3] * C[3,3]) * D[3];
//   M[2] = A[2] + (B[2,1] + C[2,1] * (C[1,1] + C[2,2]) + C[2,3] * C[3,1]) * D[1] + (B[2,2] + C[2,1] * C[1,2] + C[2,2] ^ 2.0 + C[2,3] * C[3,2]) * D[2] + (B[2,3] + C[2,1] * C[1,3] + C[2,2] * C[2,3] + C[2,3] * C[3,3]) * D[3];
//   M[3] = A[3] + (B[3,1] + C[3,1] * C[1,1] + C[3,2] * C[2,1] + C[3,3] * C[3,1]) * D[1] + (B[3,2] + C[3,1] * C[1,2] + C[3,2] * C[2,2] + C[3,3] * C[3,2]) * D[2] + (B[3,3] + C[3,1] * C[1,3] + C[3,2] * C[2,3] + C[3,3] ^ 2.0) * D[3];
//   N[1,1] = C[1,1] + B[1,1];
//   N[1,2] = C[1,2] + B[1,2];
//   N[1,3] = C[1,3] + B[1,3];
//   N[2,1] = C[2,1] + B[2,1];
//   N[2,2] = C[2,2] + B[2,2];
//   N[2,3] = C[2,3] + B[2,3];
//   N[3,1] = C[3,1] + B[3,1];
//   N[3,2] = C[3,2] + B[3,2];
//   N[3,3] = C[3,3] + B[3,3];
//   K[1,1] = C[1,1] - B[1,1];
//   K[1,2] = C[1,2] - B[1,2];
//   K[1,3] = C[1,3] - B[1,3];
//   K[2,1] = C[2,1] - B[2,1];
//   K[2,2] = C[2,2] - B[2,2];
//   K[2,3] = C[2,3] - B[2,3];
//   K[3,1] = C[3,1] - B[3,1];
//   K[3,2] = C[3,2] - B[3,2];
//   K[3,3] = C[3,3] - B[3,3];
// end MatrixAddition;
// endResult
