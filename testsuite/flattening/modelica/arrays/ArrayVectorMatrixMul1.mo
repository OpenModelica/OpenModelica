// name:     ArrayVectorMatrixMul1
// keywords: expression simplification array multiplication
// status:   correct
//
// Checks simplification of matrix-vector multiplication.
//

model ArrayVectorMatrixMul1
  Real x[3], y[3, 3], z[3];
equation
  z = x * y;
end ArrayVectorMatrixMul1;

// Result:
// class ArrayVectorMatrixMul1
//   Real x[1];
//   Real x[2];
//   Real x[3];
//   Real y[1,1];
//   Real y[1,2];
//   Real y[1,3];
//   Real y[2,1];
//   Real y[2,2];
//   Real y[2,3];
//   Real y[3,1];
//   Real y[3,2];
//   Real y[3,3];
//   Real z[1];
//   Real z[2];
//   Real z[3];
// equation
//   z[1] = x[1] * y[1,1] + x[2] * y[2,1] + x[3] * y[3,1];
//   z[2] = x[1] * y[1,2] + x[2] * y[2,2] + x[3] * y[3,2];
//   z[3] = x[1] * y[1,3] + x[2] * y[2,3] + x[3] * y[3,3];
// end ArrayVectorMatrixMul1;
// endResult
