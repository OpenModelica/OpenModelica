// name:     ArrayVectorVectorMul4
// keywords: expression simplification array multiplication
// status:   correct
//
// Checks simplification of vector-vector multiplication.
//

model ArrayVectorVectorMul4
  Real x[0], y[0], z;
equation
  z = x * y;
end ArrayVectorVectorMul4;

// Result:
// class ArrayVectorVectorMul4
//   Real z;
// equation
//   z = 0.0;
// end ArrayVectorVectorMul4;
// endResult
