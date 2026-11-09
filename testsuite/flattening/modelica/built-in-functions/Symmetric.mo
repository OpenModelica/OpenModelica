// name: Symmetric
// keywords: symmetric
// status: correct
//
// Tests the built-in symmetric function
//

model Symmetric
  constant Real A[3,3] = [1,2,3;
                 4,5,6;
                 7,8,9];
  Real B[:,:] = symmetric(A);
end Symmetric;

// Result:
// class Symmetric
//   constant Real A[1,1] = 1.0;
//   constant Real A[1,2] = 2.0;
//   constant Real A[1,3] = 3.0;
//   constant Real A[2,1] = 4.0;
//   constant Real A[2,2] = 5.0;
//   constant Real A[2,3] = 6.0;
//   constant Real A[3,1] = 7.0;
//   constant Real A[3,2] = 8.0;
//   constant Real A[3,3] = 9.0;
//   Real B[1,1];
//   Real B[1,2];
//   Real B[1,3];
//   Real B[2,1];
//   Real B[2,2];
//   Real B[2,3];
//   Real B[3,1];
//   Real B[3,2];
//   Real B[3,3];
// equation
//   B = {{1.0, 2.0, 3.0}, {2.0, 5.0, 6.0}, {3.0, 6.0, 9.0}};
// end Symmetric;
// endResult
