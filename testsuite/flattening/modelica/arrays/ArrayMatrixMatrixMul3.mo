// name:     ArrayMatrixMatrixMul3
// keywords: expression simplification array multiplication
// status:   correct
//
// Checks simplification of matrix-matrix multiplication.
//

model ArrayMatrixMatrixMul3
  Real x[1, 3], y[3, 1], z[1, 1];
equation
  z = x * y;
end ArrayMatrixMatrixMul3;

// Result:
// class ArrayMatrixMatrixMul3
//   Real x[1,1];
//   Real x[1,2];
//   Real x[1,3];
//   Real y[1,1];
//   Real y[2,1];
//   Real y[3,1];
//   Real z[1,1];
// equation
//   z[1,1] = x[1,1] * y[1,1] + x[1,2] * y[2,1] + x[1,3] * y[3,1];
// end ArrayMatrixMatrixMul3;
// endResult
