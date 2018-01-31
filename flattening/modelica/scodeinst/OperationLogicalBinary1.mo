// name: OperationLogicalBinary1
// keywords: 
// status: correct
// cflags: -d=newInst
//

model OperationLogicalBinary1
  Boolean b1, b2;
  Boolean[3] b3, b4;
  Boolean[3, 3] b5, b6;
equation
  b1 = b1 and b2;
  b1 = b1 or b2;
  b3 = b3 and b4;
  b3 = b3 or b4;
  b5 = b5 and b6;
  b5 = b5 or b6;
end OperationLogicalBinary1;

// Result:
// class OperationLogicalBinary1
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
//   b1 = b1 and b2;
//   b1 = b1 or b2;
//   b3[1] = b3[1] and b4[1];
//   b3[2] = b3[2] and b4[2];
//   b3[3] = b3[3] and b4[3];
//   b3[1] = b3[1] or b4[1];
//   b3[2] = b3[2] or b4[2];
//   b3[3] = b3[3] or b4[3];
//   b5[1,1] = b5[1,1] and b6[1,1];
//   b5[1,2] = b5[1,2] and b6[1,2];
//   b5[1,3] = b5[1,3] and b6[1,3];
//   b5[2,1] = b5[2,1] and b6[2,1];
//   b5[2,2] = b5[2,2] and b6[2,2];
//   b5[2,3] = b5[2,3] and b6[2,3];
//   b5[3,1] = b5[3,1] and b6[3,1];
//   b5[3,2] = b5[3,2] and b6[3,2];
//   b5[3,3] = b5[3,3] and b6[3,3];
//   b5[1,1] = b5[1,1] or b6[1,1];
//   b5[1,2] = b5[1,2] or b6[1,2];
//   b5[1,3] = b5[1,3] or b6[1,3];
//   b5[2,1] = b5[2,1] or b6[2,1];
//   b5[2,2] = b5[2,2] or b6[2,2];
//   b5[2,3] = b5[2,3] or b6[2,3];
//   b5[3,1] = b5[3,1] or b6[3,1];
//   b5[3,2] = b5[3,2] or b6[3,2];
//   b5[3,3] = b5[3,3] or b6[3,3];
// end OperationLogicalBinary1;
// endResult
