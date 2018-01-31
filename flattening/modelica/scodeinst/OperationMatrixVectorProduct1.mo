// name: OperationMatrixVectorProduct1
// keywords: 
// status: correct
// cflags: -d=newInst
//

model OperationMatrixVectorProduct1
  Real r2[2];
  Real r3[2, 2];
equation
  r2 = r3 * r2;
end OperationMatrixVectorProduct1;

// Result:
// class OperationMatrixVectorProduct1
//   Real r2[1];
//   Real r2[2];
//   Real r3[1,1];
//   Real r3[1,2];
//   Real r3[2,1];
//   Real r3[2,2];
// equation
//   r2[1] = r3[1,1] * r2[1] + r3[1,2] * r2[2];
//   r2[2] = r3[2,1] * r2[1] + r3[2,2] * r2[2];
// end OperationMatrixVectorProduct1;
// endResult
