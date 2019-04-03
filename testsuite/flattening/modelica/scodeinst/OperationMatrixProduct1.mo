// name: OperationMatrixProduct1
// keywords: 
// status: correct
// cflags: -d=newInst
//

model OperationMatrixProduct1
  Real[3, 3] x, y, z;
equation
  x = y * z;
end OperationMatrixProduct1;

// Result:
// class OperationMatrixProduct1
//   Real x[1,1];
//   Real x[1,2];
//   Real x[1,3];
//   Real x[2,1];
//   Real x[2,2];
//   Real x[2,3];
//   Real x[3,1];
//   Real x[3,2];
//   Real x[3,3];
//   Real y[1,1];
//   Real y[1,2];
//   Real y[1,3];
//   Real y[2,1];
//   Real y[2,2];
//   Real y[2,3];
//   Real y[3,1];
//   Real y[3,2];
//   Real y[3,3];
//   Real z[1,1];
//   Real z[1,2];
//   Real z[1,3];
//   Real z[2,1];
//   Real z[2,2];
//   Real z[2,3];
//   Real z[3,1];
//   Real z[3,2];
//   Real z[3,3];
// equation
//   x[1,1] = y[1,1] * z[1,1] + y[1,2] * z[2,1] + y[1,3] * z[3,1];
//   x[1,2] = y[1,1] * z[1,2] + y[1,2] * z[2,2] + y[1,3] * z[3,2];
//   x[1,3] = y[1,1] * z[1,3] + y[1,2] * z[2,3] + y[1,3] * z[3,3];
//   x[2,1] = y[2,1] * z[1,1] + y[2,2] * z[2,1] + y[2,3] * z[3,1];
//   x[2,2] = y[2,1] * z[1,2] + y[2,2] * z[2,2] + y[2,3] * z[3,2];
//   x[2,3] = y[2,1] * z[1,3] + y[2,2] * z[2,3] + y[2,3] * z[3,3];
//   x[3,1] = y[3,1] * z[1,1] + y[3,2] * z[2,1] + y[3,3] * z[3,1];
//   x[3,2] = y[3,1] * z[1,2] + y[3,2] * z[2,2] + y[3,3] * z[3,2];
//   x[3,3] = y[3,1] * z[1,3] + y[3,2] * z[2,3] + y[3,3] * z[3,3];
// end OperationMatrixProduct1;
// endResult
