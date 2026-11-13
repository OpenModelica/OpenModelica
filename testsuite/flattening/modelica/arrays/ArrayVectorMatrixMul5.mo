// name:     ArrayVectorMatrixMul5
// keywords: expression simplification array multiplication
// status:   correct
//
// Checks simplification of vector-matrix multiplication.
//

model ArrayVectorMatrixMul5
  Real x[0], y[0, 4], z[4];
equation
  z = x * y;
end ArrayVectorMatrixMul5;

// Result:
// class ArrayVectorMatrixMul5
//   Real z[1];
//   Real z[2];
//   Real z[3];
//   Real z[4];
// equation
//   z[1] = 0.0;
//   z[2] = 0.0;
//   z[3] = 0.0;
//   z[4] = 0.0;
// end ArrayVectorMatrixMul5;
// endResult
