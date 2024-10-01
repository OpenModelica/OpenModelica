// name: OperationMatrixProduct3
// keywords:
// status: correct
//

model OperationMatrixProduct3
  Real x[2, 0];
  Real y[0, 2];
  Real z[2, 2];
equation
  z = x * y;
end OperationMatrixProduct3;

// Result:
// class OperationMatrixProduct3
//   Real z[1,1];
//   Real z[1,2];
//   Real z[2,1];
//   Real z[2,2];
// equation
//   z[1,1] = 0.0;
//   z[1,2] = 0.0;
//   z[2,1] = 0.0;
//   z[2,2] = 0.0;
// end OperationMatrixProduct3;
// endResult
