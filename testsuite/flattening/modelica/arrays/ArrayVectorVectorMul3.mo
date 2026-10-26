// name:     ArrayVectorVectorMul3
// keywords: expression simplification array multiplication
// status:   correct
//
// Checks simplification of vector-vector multiplication.
//

model ArrayVectorVectorMul3
  Real x[15], y[15], z;
equation
  z = x * y;
end ArrayVectorVectorMul3;

// Result:
// class ArrayVectorVectorMul3
//   Real x[1];
//   Real x[2];
//   Real x[3];
//   Real x[4];
//   Real x[5];
//   Real x[6];
//   Real x[7];
//   Real x[8];
//   Real x[9];
//   Real x[10];
//   Real x[11];
//   Real x[12];
//   Real x[13];
//   Real x[14];
//   Real x[15];
//   Real y[1];
//   Real y[2];
//   Real y[3];
//   Real y[4];
//   Real y[5];
//   Real y[6];
//   Real y[7];
//   Real y[8];
//   Real y[9];
//   Real y[10];
//   Real y[11];
//   Real y[12];
//   Real y[13];
//   Real y[14];
//   Real y[15];
//   Real z;
// equation
//   z = x[1] * y[1] + x[2] * y[2] + x[3] * y[3] + x[4] * y[4] + x[5] * y[5] + x[6] * y[6] + x[7] * y[7] + x[8] * y[8] + x[9] * y[9] + x[10] * y[10] + x[11] * y[11] + x[12] * y[12] + x[13] * y[13] + x[14] * y[14] + x[15] * y[15];
// end ArrayVectorVectorMul3;
// endResult
