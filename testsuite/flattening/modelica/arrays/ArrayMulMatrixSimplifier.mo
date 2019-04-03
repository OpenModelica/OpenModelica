// name:     ArrayMulMatrixSimplifier
// keywords: Simplifier
// status:   correct
//
// Check si that the multiplication with array * matrix, simplify process works.
// Also tests builtin pre function.
//

model ArrayMulMatrixSimplifier
  parameter Real A[:,size(A, 1)]={{1,0},{0,1}};
  parameter Real B[size(A, 1),:]={{1},{1}};
  output Real x[size(A, 1)];
  output Real y[size(A, 1)];
  Real u[1];

equation
      x= pre(x)*A + B*u;
      y= A*pre(x) + B*u;
end ArrayMulMatrixSimplifier;
// Result:
// class ArrayMulMatrixSimplifier
//   parameter Real A[1,1] = 1.0;
//   parameter Real A[1,2] = 0.0;
//   parameter Real A[2,1] = 0.0;
//   parameter Real A[2,2] = 1.0;
//   parameter Real B[1,1] = 1.0;
//   parameter Real B[2,1] = 1.0;
//   output Real x[1];
//   output Real x[2];
//   output Real y[1];
//   output Real y[2];
//   Real u[1];
// equation
//   x[1] = pre(x[1]) * A[1,1] + pre(x[2]) * A[2,1] + B[1,1] * u[1];
//   x[2] = pre(x[1]) * A[1,2] + pre(x[2]) * A[2,2] + B[2,1] * u[1];
//   y[1] = A[1,1] * pre(x[1]) + A[1,2] * pre(x[2]) + B[1,1] * u[1];
//   y[2] = A[2,1] * pre(x[1]) + A[2,2] * pre(x[2]) + B[2,1] * u[1];
// end ArrayMulMatrixSimplifier;
// endResult
