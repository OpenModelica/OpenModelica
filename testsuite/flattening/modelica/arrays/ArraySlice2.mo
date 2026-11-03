// name:     ArraySlice2
// keywords: array slice bug1602
// status:   correct
//
// Slice subscripting of parameter arrays.
//

model ArraySlice2
  parameter Real ABCD[5,5] = ones(5,5);
  parameter Real A[:,:] = ABCD[1:end-1,1:end-1];
  parameter Real B[:,:] = ABCD[1:end-1,end:end];
  parameter Real C[:,:] = ABCD[end:end,1:end-1];
  parameter Real D[:,:] = matrix(ABCD[end,end]);
end ArraySlice2;

// Result:
// class ArraySlice2
//   parameter Real ABCD[1,1] = 1.0;
//   parameter Real ABCD[1,2] = 1.0;
//   parameter Real ABCD[1,3] = 1.0;
//   parameter Real ABCD[1,4] = 1.0;
//   parameter Real ABCD[1,5] = 1.0;
//   parameter Real ABCD[2,1] = 1.0;
//   parameter Real ABCD[2,2] = 1.0;
//   parameter Real ABCD[2,3] = 1.0;
//   parameter Real ABCD[2,4] = 1.0;
//   parameter Real ABCD[2,5] = 1.0;
//   parameter Real ABCD[3,1] = 1.0;
//   parameter Real ABCD[3,2] = 1.0;
//   parameter Real ABCD[3,3] = 1.0;
//   parameter Real ABCD[3,4] = 1.0;
//   parameter Real ABCD[3,5] = 1.0;
//   parameter Real ABCD[4,1] = 1.0;
//   parameter Real ABCD[4,2] = 1.0;
//   parameter Real ABCD[4,3] = 1.0;
//   parameter Real ABCD[4,4] = 1.0;
//   parameter Real ABCD[4,5] = 1.0;
//   parameter Real ABCD[5,1] = 1.0;
//   parameter Real ABCD[5,2] = 1.0;
//   parameter Real ABCD[5,3] = 1.0;
//   parameter Real ABCD[5,4] = 1.0;
//   parameter Real ABCD[5,5] = 1.0;
//   parameter Real A[1,1] = ABCD[1,1];
//   parameter Real A[1,2] = ABCD[1,2];
//   parameter Real A[1,3] = ABCD[1,3];
//   parameter Real A[1,4] = ABCD[1,4];
//   parameter Real A[2,1] = ABCD[2,1];
//   parameter Real A[2,2] = ABCD[2,2];
//   parameter Real A[2,3] = ABCD[2,3];
//   parameter Real A[2,4] = ABCD[2,4];
//   parameter Real A[3,1] = ABCD[3,1];
//   parameter Real A[3,2] = ABCD[3,2];
//   parameter Real A[3,3] = ABCD[3,3];
//   parameter Real A[3,4] = ABCD[3,4];
//   parameter Real A[4,1] = ABCD[4,1];
//   parameter Real A[4,2] = ABCD[4,2];
//   parameter Real A[4,3] = ABCD[4,3];
//   parameter Real A[4,4] = ABCD[4,4];
//   parameter Real B[1,1] = ABCD[1,5];
//   parameter Real B[2,1] = ABCD[2,5];
//   parameter Real B[3,1] = ABCD[3,5];
//   parameter Real B[4,1] = ABCD[4,5];
//   parameter Real C[1,1] = ABCD[5,1];
//   parameter Real C[1,2] = ABCD[5,2];
//   parameter Real C[1,3] = ABCD[5,3];
//   parameter Real C[1,4] = ABCD[5,4];
//   parameter Real D[1,1] = ABCD[5,5];
// end ArraySlice2;
// endResult
