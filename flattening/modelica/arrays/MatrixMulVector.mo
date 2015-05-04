// status: correct

model MatrixMulVector
  Real x[4];
  constant Real A[:,:] = {{1,0,2,3},{-1,2,0,0},{2,0,0,0},{0,0,1,1}};
  Real b[:] = {1,2,3,time};
equation
  A*x = b;
end MatrixMulVector;

// Result:
// class MatrixMulVector
//   Real x[1];
//   Real x[2];
//   Real x[3];
//   Real x[4];
//   constant Real A[1,1] = 1.0;
//   constant Real A[1,2] = 0.0;
//   constant Real A[1,3] = 2.0;
//   constant Real A[1,4] = 3.0;
//   constant Real A[2,1] = -1.0;
//   constant Real A[2,2] = 2.0;
//   constant Real A[2,3] = 0.0;
//   constant Real A[2,4] = 0.0;
//   constant Real A[3,1] = 2.0;
//   constant Real A[3,2] = 0.0;
//   constant Real A[3,3] = 0.0;
//   constant Real A[3,4] = 0.0;
//   constant Real A[4,1] = 0.0;
//   constant Real A[4,2] = 0.0;
//   constant Real A[4,3] = 1.0;
//   constant Real A[4,4] = 1.0;
//   Real b[1];
//   Real b[2];
//   Real b[3];
//   Real b[4];
// equation
//   b = {1.0, 2.0, 3.0, time};
//   x[1] + 2.0 * x[3] + 3.0 * x[4] = b[1];
//   2.0 * x[2] - x[1] = b[2];
//   2.0 * x[1] = b[3];
//   x[3] + x[4] = b[4];
// end MatrixMulVector;
// endResult
