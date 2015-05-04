// name:     MatrixSubtraction
// keywords: matrix subtraction simplify
// status:   correct
//
// Tests simplification of matrix subtraction.
//

model MatrixSubtraction
  parameter Real u[3, 1] = [1; 1; 1];
  parameter Real v[3, 1] = [1; 0; 0];
  Real M[3, 3];
  Real A[3, 1];
equation
  M = [1, 0, 0; 0, 1, 0; 0, 0, 1];
  A = u + v - M * (v - u);
end MatrixSubtraction;


// Result:
// class MatrixSubtraction
//   parameter Real u[1,1] = 1.0;
//   parameter Real u[2,1] = 1.0;
//   parameter Real u[3,1] = 1.0;
//   parameter Real v[1,1] = 1.0;
//   parameter Real v[2,1] = 0.0;
//   parameter Real v[3,1] = 0.0;
//   Real M[1,1];
//   Real M[1,2];
//   Real M[1,3];
//   Real M[2,1];
//   Real M[2,2];
//   Real M[2,3];
//   Real M[3,1];
//   Real M[3,2];
//   Real M[3,3];
//   Real A[1,1];
//   Real A[2,1];
//   Real A[3,1];
// equation
//   M[1,1] = 1.0;
//   M[1,2] = 0.0;
//   M[1,3] = 0.0;
//   M[2,1] = 0.0;
//   M[2,2] = 1.0;
//   M[2,3] = 0.0;
//   M[3,1] = 0.0;
//   M[3,2] = 0.0;
//   M[3,3] = 1.0;
//   A[1,1] = u[1,1] + v[1,1] - (M[1,1] * (v[1,1] - u[1,1]) + M[1,2] * (v[2,1] - u[2,1]) + M[1,3] * (v[3,1] - u[3,1]));
//   A[2,1] = u[2,1] + v[2,1] - (M[2,1] * (v[1,1] - u[1,1]) + M[2,2] * (v[2,1] - u[2,1]) + M[2,3] * (v[3,1] - u[3,1]));
//   A[3,1] = u[3,1] + v[3,1] - (M[3,1] * (v[1,1] - u[1,1]) + M[3,2] * (v[2,1] - u[2,1]) + M[3,3] * (v[3,1] - u[3,1]));
// end MatrixSubtraction;
// endResult
