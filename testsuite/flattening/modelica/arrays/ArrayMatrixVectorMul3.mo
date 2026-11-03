// name:     ArrayVectorMatrixMul3
// keywords: expression simplification array multiplication
// status:   correct
//
// Checks simplification of vector-matrix multiplication.
//

model ArrayVectorMatrixMul3
  Real x[4, 5], y[5], z[4];
equation
  z = x * y;
end ArrayVectorMatrixMul3;

// Result:
// class ArrayVectorMatrixMul3
//   Real x[1,1];
//   Real x[1,2];
//   Real x[1,3];
//   Real x[1,4];
//   Real x[1,5];
//   Real x[2,1];
//   Real x[2,2];
//   Real x[2,3];
//   Real x[2,4];
//   Real x[2,5];
//   Real x[3,1];
//   Real x[3,2];
//   Real x[3,3];
//   Real x[3,4];
//   Real x[3,5];
//   Real x[4,1];
//   Real x[4,2];
//   Real x[4,3];
//   Real x[4,4];
//   Real x[4,5];
//   Real y[1];
//   Real y[2];
//   Real y[3];
//   Real y[4];
//   Real y[5];
//   Real z[1];
//   Real z[2];
//   Real z[3];
//   Real z[4];
// equation
//   z[1] = x[1,1] * y[1] + x[1,2] * y[2] + x[1,3] * y[3] + x[1,4] * y[4] + x[1,5] * y[5];
//   z[2] = x[2,1] * y[1] + x[2,2] * y[2] + x[2,3] * y[3] + x[2,4] * y[4] + x[2,5] * y[5];
//   z[3] = x[3,1] * y[1] + x[3,2] * y[2] + x[3,3] * y[3] + x[3,4] * y[4] + x[3,5] * y[5];
//   z[4] = x[4,1] * y[1] + x[4,2] * y[2] + x[4,3] * y[3] + x[4,4] * y[4] + x[4,5] * y[5];
// end ArrayVectorMatrixMul3;
// endResult
