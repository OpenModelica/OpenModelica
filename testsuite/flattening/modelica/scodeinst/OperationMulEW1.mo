// name: OperationMulEW1
// keywords: 
// status: correct
// cflags: -d=newInst
//

model OperationMulEW1
  Real r1;
  Real r2[2];
  Real r3[2, 2];
equation
  r1 = r1 .* r1;
  r2 = r1 .* r2;
  r2 = r2 .* r1;
  r3 = r3 .* r3;
end OperationMulEW1;

// Result:
// class OperationMulEW1
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
//   r3[1,1] = r3[1,1] * r3[1,1];
//   r3[1,2] = r3[1,2] * r3[1,2];
//   r3[2,1] = r3[2,1] * r3[2,1];
//   r3[2,2] = r3[2,2] * r3[2,2];
// end OperationMulEW1;
// endResult
