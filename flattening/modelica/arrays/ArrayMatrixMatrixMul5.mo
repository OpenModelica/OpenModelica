// name:     ArrayMatrixMatrixMul5
// keywords: expression simplification array multiplication
// status:   correct
//
// Checks simplification of matrix-matrix multiplication.
//

model ArrayMatrixMatrixMul5
  Real x[0, 3], y[3, 0], z[0, 0];
equation
  z = x * y;
end ArrayMatrixMatrixMul5;

// Result:
// class ArrayMatrixMatrixMul5
// end ArrayMatrixMatrixMul5;
// endResult
