// name: OperationMul1
// keywords: 
// status: correct
// cflags: -d=newInst
//

model OperationMul1
  Real r1;
  Real r2[2];
  Real r3[2, 2];
equation
  r1 = r1 * r1;
  r2 = r1 * r2;
  r2 = r2 * r1;
  r3 = r1 * r3;
  r3 = r3 * r1;
end OperationMul1;

// Result:
// class OperationMul1
//   Real r1;
//   Real r2[1];
//   Real r2[2];
//   Real r3[1,1];
//   Real r3[1,2];
//   Real r3[2,1];
//   Real r3[2,2];
// equation
//   r1 = r1 * r1;
//   r2[1] = r1 * r2[1];
//   r2[2] = r1 * r2[2];
//   r2[1] = r2[1] * r1;
//   r2[2] = r2[2] * r1;
//   r3[1,1] = r1 * r3[1,1];
//   r3[1,2] = r1 * r3[1,2];
//   r3[2,1] = r1 * r3[2,1];
//   r3[2,2] = r1 * r3[2,2];
//   r3[1,1] = r3[1,1] * r1;
//   r3[1,2] = r3[1,2] * r1;
//   r3[2,1] = r3[2,1] * r1;
//   r3[2,2] = r3[2,2] * r1;
// end OperationMul1;
// endResult
