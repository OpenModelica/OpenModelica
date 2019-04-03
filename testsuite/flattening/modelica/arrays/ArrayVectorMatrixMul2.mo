// name:     ArrayVectorMatrixMul2
// keywords: expression simplification array multiplication
// status:   correct
//
// Checks simplification of vector-matrix multiplication.
//

model ArrayVectorMatrixMul2
  Real x[3], y[3, 1], z[1];
equation
  z = x * y;
end ArrayVectorMatrixMul2;

// Result:
// class ArrayVectorMatrixMul2
//   Real x[1];
//   Real x[2];
//   Real x[3];
//   Real y[1,1];
//   Real y[2,1];
//   Real y[3,1];
//   Real z[1];
// equation
//   z[1] = x[1] * y[1,1] + x[2] * y[2,1] + x[3] * y[3,1];
// end ArrayVectorMatrixMul2;
// endResult
