// name: OperationSub1
// keywords: 
// status: correct
// cflags: -d=newInst
//

model OperationSub1
  Integer i1;
  Integer i2[2];
  Integer i3[3, 3];
  Real r1;
  Real r2[2];
  Real r3[3, 3];
equation
  i1 = 1 - 2; 
  i2 = {1, 2} - {3, 4};
  i3 = identity(3) - identity(3);
  r1 = 1.0 - 2; 
  r2 = {1, 2.0} - {3.0, 4};
  r3 = identity(3) - identity(3);
end OperationSub1;

// Result:
// class OperationSub1
//   Integer i1;
//   Integer i2[1];
//   Integer i2[2];
//   Integer i3[1,1];
//   Integer i3[1,2];
//   Integer i3[1,3];
//   Integer i3[2,1];
//   Integer i3[2,2];
//   Integer i3[2,3];
//   Integer i3[3,1];
//   Integer i3[3,2];
//   Integer i3[3,3];
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
//   i1 = -1;
//   i2[1] = -2;
//   i2[2] = -2;
//   i3[1,1] = 0;
//   i3[1,2] = 0;
//   i3[1,3] = 0;
//   i3[2,1] = 0;
//   i3[2,2] = 0;
//   i3[2,3] = 0;
//   i3[3,1] = 0;
//   i3[3,2] = 0;
//   i3[3,3] = 0;
//   r1 = -1.0;
//   r2[1] = -2.0;
//   r2[2] = -2.0;
//   r3[1,1] = 0.0;
//   r3[1,2] = 0.0;
//   r3[1,3] = 0.0;
//   r3[2,1] = 0.0;
//   r3[2,2] = 0.0;
//   r3[2,3] = 0.0;
//   r3[3,1] = 0.0;
//   r3[3,2] = 0.0;
//   r3[3,3] = 0.0;
// end OperationSub1;
// endResult
