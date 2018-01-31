// name: OperationAddEW1
// keywords: 
// status: correct
// cflags: -d=newInst
//

model OperationAddEW1
  Integer i1;
  Integer i2[2];
  Integer i3[3, 3];
  Real r1;
  Real r2[2];
equation
  i2 = i2 .+ i1;
  i2 = i1 .+ i2;
  i3 = i3 .+ i1;
  i3 = i1 .+ i3;
  r2 = i2 .+ r1;
  r2 = r1 .+ i2;
end OperationAddEW1;

// Result:
// class OperationAddEW1
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
// equation
//   i2[1] = i2[1] + i1;
//   i2[2] = i2[2] + i1;
//   i2[1] = i1 + i2[1];
//   i2[2] = i1 + i2[2];
//   i3[1,1] = i3[1,1] + i1;
//   i3[1,2] = i3[1,2] + i1;
//   i3[1,3] = i3[1,3] + i1;
//   i3[2,1] = i3[2,1] + i1;
//   i3[2,2] = i3[2,2] + i1;
//   i3[2,3] = i3[2,3] + i1;
//   i3[3,1] = i3[3,1] + i1;
//   i3[3,2] = i3[3,2] + i1;
//   i3[3,3] = i3[3,3] + i1;
//   i3[1,1] = i1 + i3[1,1];
//   i3[1,2] = i1 + i3[1,2];
//   i3[1,3] = i1 + i3[1,3];
//   i3[2,1] = i1 + i3[2,1];
//   i3[2,2] = i1 + i3[2,2];
//   i3[2,3] = i1 + i3[2,3];
//   i3[3,1] = i1 + i3[3,1];
//   i3[3,2] = i1 + i3[3,2];
//   i3[3,3] = i1 + i3[3,3];
//   r2[1] = /*Real*/(i2[1]) + r1;
//   r2[2] = /*Real*/(i2[2]) + r1;
//   r2[1] = r1 + /*Real*/(i2[1]);
//   r2[2] = r1 + /*Real*/(i2[2]);
// end OperationAddEW1;
// endResult
