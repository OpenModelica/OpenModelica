// name:     ArrayVectorVectorMul1
// keywords: expression simplification array multiplication
// status:   correct
//
// Checks simplification of vector-vector multiplication.
//

model ArrayVectorVectorMul1
  Real x[3], y[3], z;
equation
  z = x * y;
end ArrayVectorVectorMul1;

// Result:
// class ArrayVectorVectorMul1
//   Real x[1];
//   Real x[2];
//   Real x[3];
//   Real y[1];
//   Real y[2];
//   Real y[3];
//   Real z;
// equation
//   z = x[1] * y[1] + x[2] * y[2] + x[3] * y[3];
// end ArrayVectorVectorMul1;
// endResult
