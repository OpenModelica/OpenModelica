// name:     ArrayVectorMatrixMul4
// keywords: expression simplification array multiplication
// status:   correct
//
// Checks simplification of vector-matrix multiplication.
//

model ArrayVectorMatrixMul4
  Real x[0, 3], y[3], z[0];
equation
  z = x * y;
end ArrayVectorMatrixMul4;

// Result:
// class ArrayVectorMatrixMul4
//   Real y[1];
//   Real y[2];
//   Real y[3];
// end ArrayVectorMatrixMul4;
// endResult
