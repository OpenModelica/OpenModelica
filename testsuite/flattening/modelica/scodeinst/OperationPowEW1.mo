// name: OperationPow3
// keywords: 
// status: correct
// cflags: -d=newInst
//

model OperationPow3
  Real r1, r2;
  Real r3[3];
  Real r4[3, 3];
equation
  r1 = r1 .^ r2;
  r3 = r3 .^ r1;
  r3 = r1 .^ r3;
  r4 = r1 .^ r4;
  r4 = r4 .^ r1;
end OperationPow3;

// Result:
// class OperationPow3
//   Real r1;
//   Real r2;
//   Real r3[1];
//   Real r3[2];
//   Real r3[3];
//   Real r4[1,1];
//   Real r4[1,2];
//   Real r4[1,3];
//   Real r4[2,1];
//   Real r4[2,2];
//   Real r4[2,3];
//   Real r4[3,1];
//   Real r4[3,2];
//   Real r4[3,3];
// equation
//   r1 = r1 ^ r2;
//   r3[1] = r3[1] ^ r1;
//   r3[2] = r3[2] ^ r1;
//   r3[3] = r3[3] ^ r1;
//   r3[1] = r1 ^ r3[1];
//   r3[2] = r1 ^ r3[2];
//   r3[3] = r1 ^ r3[3];
//   r4[1,1] = r1 ^ r4[1,1];
//   r4[1,2] = r1 ^ r4[1,2];
//   r4[1,3] = r1 ^ r4[1,3];
//   r4[2,1] = r1 ^ r4[2,1];
//   r4[2,2] = r1 ^ r4[2,2];
//   r4[2,3] = r1 ^ r4[2,3];
//   r4[3,1] = r1 ^ r4[3,1];
//   r4[3,2] = r1 ^ r4[3,2];
//   r4[3,3] = r1 ^ r4[3,3];
//   r4[1,1] = r4[1,1] ^ r1;
//   r4[1,2] = r4[1,2] ^ r1;
//   r4[1,3] = r4[1,3] ^ r1;
//   r4[2,1] = r4[2,1] ^ r1;
//   r4[2,2] = r4[2,2] ^ r1;
//   r4[2,3] = r4[2,3] ^ r1;
//   r4[3,1] = r4[3,1] ^ r1;
//   r4[3,2] = r4[3,2] ^ r1;
//   r4[3,3] = r4[3,3] ^ r1;
// end OperationPow3;
// endResult
