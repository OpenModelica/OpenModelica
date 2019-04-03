// name:     ConstantSize
// keywords: size constant
// status:   correct
//
// Tests that a size call with constant arguments is evaluted correctly.
//

model ConstantSize
  Real A[3];
  Real B[2, 3];
  Integer x, y, z;
  Integer x2[2];
equation
  x = size(A, 1);
  y = size(B, 1);
  z = size(B, 2);
  x2 = size(B);
end ConstantSize;

// Result:
// class ConstantSize
//   Real A[1];
//   Real A[2];
//   Real A[3];
//   Real B[1,1];
//   Real B[1,2];
//   Real B[1,3];
//   Real B[2,1];
//   Real B[2,2];
//   Real B[2,3];
//   Integer x;
//   Integer y;
//   Integer z;
//   Integer x2[1];
//   Integer x2[2];
// equation
//   x = 3;
//   y = 2;
//   z = 3;
//   x2[1] = 2;
//   x2[2] = 3;
// end ConstantSize;
// endResult
