// name: OperationUnary1
// keywords: 
// status: correct
// cflags: -d=newInst
//

model OperationUnary1
  Real r1, r2;
  Real[2] r3, r4;
  Real[2, 2] r5, r6;
  Integer i1, i2;
  Integer[2] i3, i4;
  Integer[2, 2] i5, i6;
equation
  r1 = -r2;
  r3 = -r4;
  r5 = -r6;
  i1 = -i1;
  i3 = -i4;
  i5 = -i6;
  r1 = +r2;
  r3 = +r4;
  r5 = +r6;
  i1 = +i1;
  i3 = +i4;
  i5 = +i6;
end OperationUnary1;

// Result:
// class OperationUnary1
//   Real r1;
//   Real r2;
//   Real r3[1];
//   Real r3[2];
//   Real r4[1];
//   Real r4[2];
//   Real r5[1,1];
//   Real r5[1,2];
//   Real r5[2,1];
//   Real r5[2,2];
//   Real r6[1,1];
//   Real r6[1,2];
//   Real r6[2,1];
//   Real r6[2,2];
//   Integer i1;
//   Integer i2;
//   Integer i3[1];
//   Integer i3[2];
//   Integer i4[1];
//   Integer i4[2];
//   Integer i5[1,1];
//   Integer i5[1,2];
//   Integer i5[2,1];
//   Integer i5[2,2];
//   Integer i6[1,1];
//   Integer i6[1,2];
//   Integer i6[2,1];
//   Integer i6[2,2];
// equation
//   r1 = -r2;
//   r3[1] = -r4[1];
//   r3[2] = -r4[2];
//   r5[1,1] = -r6[1,1];
//   r5[1,2] = -r6[1,2];
//   r5[2,1] = -r6[2,1];
//   r5[2,2] = -r6[2,2];
//   i1 = -i1;
//   i3[1] = -i4[1];
//   i3[2] = -i4[2];
//   i5[1,1] = -i6[1,1];
//   i5[1,2] = -i6[1,2];
//   i5[2,1] = -i6[2,1];
//   i5[2,2] = -i6[2,2];
//   r1 = r2;
//   r3[1] = r4[1];
//   r3[2] = r4[2];
//   r5[1,1] = r6[1,1];
//   r5[1,2] = r6[1,2];
//   r5[2,1] = r6[2,1];
//   r5[2,2] = r6[2,2];
//   i1 = i1;
//   i3[1] = i4[1];
//   i3[2] = i4[2];
//   i5[1,1] = i6[1,1];
//   i5[1,2] = i6[1,2];
//   i5[2,1] = i6[2,1];
//   i5[2,2] = i6[2,2];
// end OperationUnary1;
// endResult
