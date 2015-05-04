// name:     ArrayVectorVectorMul2
// keywords: expression simplification array multiplication
// status:   correct
//
// Checks simplification of vector-vector multiplication.
//

model ArrayVectorVectorMul2
  Real x[1], y[1], z;
equation
  z = x * y;
end ArrayVectorVectorMul2;

// Result:
// class ArrayVectorVectorMul2
//   Real x[1];
//   Real y[1];
//   Real z;
// equation
//   z = x[1] * y[1];
// end ArrayVectorVectorMul2;
// endResult
