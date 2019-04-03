// name:     ArrayVectorMatrixMul4
// keywords: expression simplification array multiplication
// status:   correct
//
// Checks simplification of vector-matrix multiplication.
//

model ArrayVectorMatrixMul4
  Real x[3], y[3, 0], z[0];
equation
  z = x * y;
end ArrayVectorMatrixMul4;

// Result:
// class ArrayVectorMatrixMul4
//   Real x[1];
//   Real x[2];
//   Real x[3];
// end ArrayVectorMatrixMul4;
// endResult
