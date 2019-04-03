// name:     ArrayMatrixMatrixMul6
// keywords: expression simplification array multiplication
// status:   correct
//
// Checks simplification of matrix-matrix multiplication.
//

model ArrayMatrixMatrixMul6
  Real x[4, 0], y[0, 4], z[4, 4];
equation
  z = x * y;
end ArrayMatrixMatrixMul6;

// Result:
// class ArrayMatrixMatrixMul6
//   Real z[1,1];
//   Real z[1,2];
//   Real z[1,3];
//   Real z[1,4];
//   Real z[2,1];
//   Real z[2,2];
//   Real z[2,3];
//   Real z[2,4];
//   Real z[3,1];
//   Real z[3,2];
//   Real z[3,3];
//   Real z[3,4];
//   Real z[4,1];
//   Real z[4,2];
//   Real z[4,3];
//   Real z[4,4];
// equation
//   z[1,1] = 0.0;
//   z[1,2] = 0.0;
//   z[1,3] = 0.0;
//   z[1,4] = 0.0;
//   z[2,1] = 0.0;
//   z[2,2] = 0.0;
//   z[2,3] = 0.0;
//   z[2,4] = 0.0;
//   z[3,1] = 0.0;
//   z[3,2] = 0.0;
//   z[3,3] = 0.0;
//   z[3,4] = 0.0;
//   z[4,1] = 0.0;
//   z[4,2] = 0.0;
//   z[4,3] = 0.0;
//   z[4,4] = 0.0;
// end ArrayMatrixMatrixMul6;
// endResult
