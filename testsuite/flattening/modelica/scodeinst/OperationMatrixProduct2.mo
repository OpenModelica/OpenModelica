// name: OperationMatrixProduct2
// keywords:
// status: correct
//

model OperationMatrixProduct2
  Real x[2, 3];
  Real y[3, 2];
  Real z[2, 2];
equation
  z = x * y;
end OperationMatrixProduct2;

// Result:
// class OperationMatrixProduct2
//   Real x[1,1];
//   Real x[1,2];
//   Real x[1,3];
//   Real x[2,1];
//   Real x[2,2];
//   Real x[2,3];
//   Real y[1,1];
//   Real y[1,2];
//   Real y[2,1];
//   Real y[2,2];
//   Real y[3,1];
//   Real y[3,2];
//   Real z[1,1];
//   Real z[1,2];
//   Real z[2,1];
//   Real z[2,2];
// equation
//   z[1,1] = x[1,1] * y[1,1] + x[1,2] * y[2,1] + x[1,3] * y[3,1];
//   z[1,2] = x[1,1] * y[1,2] + x[1,2] * y[2,2] + x[1,3] * y[3,2];
//   z[2,1] = x[2,1] * y[1,1] + x[2,2] * y[2,1] + x[2,3] * y[3,1];
//   z[2,2] = x[2,1] * y[1,2] + x[2,2] * y[2,2] + x[2,3] * y[3,2];
// end OperationMatrixProduct2;
// endResult
