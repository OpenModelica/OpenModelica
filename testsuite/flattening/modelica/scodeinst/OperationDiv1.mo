// name: OperationDiv1
// keywords: 
// status: correct
// cflags: -d=newInst
//

model OperationDiv1
  Integer i1;
  Integer i2[2];
  Real r1;
  Real r2[2];
  Real r3[3, 3];
equation
  r1 = r1 / r1;
  r2 = r2 / r1;
  r3 = r3 / r1;
  r2 = i2 / i1;
end OperationDiv1;

// Result:
// class OperationDiv1
//   Integer i1;
//   Integer i2[1];
//   Integer i2[2];
//   Real r1;
//   Real r2[1];
//   Real r2[2];
//   Real r3[1,1];
//   Real r3[1,2];
//   Real r3[1,3];
//   Real r3[2,1];
//   Real r3[2,2];
//   Real r3[2,3];
//   Real r3[3,1];
//   Real r3[3,2];
//   Real r3[3,3];
// equation
//   r1 = r1 / r1;
//   r2[1] = r2[1] / r1;
//   r2[2] = r2[2] / r1;
//   r3[1,1] = r3[1,1] / r1;
//   r3[1,2] = r3[1,2] / r1;
//   r3[1,3] = r3[1,3] / r1;
//   r3[2,1] = r3[2,1] / r1;
//   r3[2,2] = r3[2,2] / r1;
//   r3[2,3] = r3[2,3] / r1;
//   r3[3,1] = r3[3,1] / r1;
//   r3[3,2] = r3[3,2] / r1;
//   r3[3,3] = r3[3,3] / r1;
//   r2[1] = /*Real*/(i2[1]) / /*Real*/(i1);
//   r2[2] = /*Real*/(i2[2]) / /*Real*/(i1);
// end OperationDiv1;
// endResult
