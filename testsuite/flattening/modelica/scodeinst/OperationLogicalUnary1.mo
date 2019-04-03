// name: OperationLogicalUnary1
// keywords: 
// status: correct
// cflags: -d=newInst
//

model OperationLogicalUnary1
  Boolean b1, b2;
  Boolean[3] b3, b4;
  Boolean[3, 3] b5, b6;
equation
  b1 = not b2;
  b3 = not b4;
  b5 = not b6;
end OperationLogicalUnary1;

// Result:
// class OperationLogicalUnary1
//   Boolean b1;
//   Boolean b2;
//   Boolean b3[1];
//   Boolean b3[2];
//   Boolean b3[3];
//   Boolean b4[1];
//   Boolean b4[2];
//   Boolean b4[3];
//   Boolean b5[1,1];
//   Boolean b5[1,2];
//   Boolean b5[1,3];
//   Boolean b5[2,1];
//   Boolean b5[2,2];
//   Boolean b5[2,3];
//   Boolean b5[3,1];
//   Boolean b5[3,2];
//   Boolean b5[3,3];
//   Boolean b6[1,1];
//   Boolean b6[1,2];
//   Boolean b6[1,3];
//   Boolean b6[2,1];
//   Boolean b6[2,2];
//   Boolean b6[2,3];
//   Boolean b6[3,1];
//   Boolean b6[3,2];
//   Boolean b6[3,3];
// equation
//   b1 = not b2;
//   b3[1] = not b4[1];
//   b3[2] = not b4[2];
//   b3[3] = not b4[3];
//   b5[1,1] = not b6[1,1];
//   b5[1,2] = not b6[1,2];
//   b5[1,3] = not b6[1,3];
//   b5[2,1] = not b6[2,1];
//   b5[2,2] = not b6[2,2];
//   b5[2,3] = not b6[2,3];
//   b5[3,1] = not b6[3,1];
//   b5[3,2] = not b6[3,2];
//   b5[3,3] = not b6[3,3];
// end OperationLogicalUnary1;
// endResult
