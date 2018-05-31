// name: CevalSub1
// keywords:
// status: correct
// cflags: -d=newInst
//

model CevalSub1
  constant Integer i1 = 1 - 2;
  constant Integer i2[:] = {1, 2, 3} - {3, 4, 5};
  constant Integer i3[:, :] = {{1, 2}, {3, 4}} - {{5, 6}, {7, 8}};
  constant Integer i4[:] = 1 .- {1, 2, 3};
  constant Integer i5[:] = {1, 2, 3} .- 1;
  constant Integer i6[:] = zeros(0) - zeros(0);
  constant Integer i7 = -1;
  constant Integer i8[:] = -{1, 2, 3};

  constant Real r1 = 1 - 2;
  constant Real r2[:] = {1, 2, 3} - {3, 4, 5};
  constant Real r3[:, :] = {{1, 2}, {3, 4}} - {{5, 6}, {7, 8}};
  constant Real r4[:] = 1 .- {1, 2, 3};
  constant Real r5[:] = {1, 2, 3} .- 1;
  constant Real r6[:] = zeros(0) - zeros(0);
  constant Real r7 = -1.0;
  constant Real r8[:] = -{1.0, 2.0, 3.0};
end CevalSub1;

// Result:
// class CevalSub1
//   constant Integer i1 = -1;
//   constant Integer i2[1] = -2;
//   constant Integer i2[2] = -2;
//   constant Integer i2[3] = -2;
//   constant Integer i3[1,1] = -4;
//   constant Integer i3[1,2] = -4;
//   constant Integer i3[2,1] = -4;
//   constant Integer i3[2,2] = -4;
//   constant Integer i4[1] = 0;
//   constant Integer i4[2] = -1;
//   constant Integer i4[3] = -2;
//   constant Integer i5[1] = 0;
//   constant Integer i5[2] = 1;
//   constant Integer i5[3] = 2;
//   constant Integer i7 = -1;
//   constant Integer i8[1] = -1;
//   constant Integer i8[2] = -2;
//   constant Integer i8[3] = -3;
//   constant Real r1 = -1.0;
//   constant Real r2[1] = -2.0;
//   constant Real r2[2] = -2.0;
//   constant Real r2[3] = -2.0;
//   constant Real r3[1,1] = -4.0;
//   constant Real r3[1,2] = -4.0;
//   constant Real r3[2,1] = -4.0;
//   constant Real r3[2,2] = -4.0;
//   constant Real r4[1] = 0.0;
//   constant Real r4[2] = -1.0;
//   constant Real r4[3] = -2.0;
//   constant Real r5[1] = 0.0;
//   constant Real r5[2] = 1.0;
//   constant Real r5[3] = 2.0;
//   constant Real r7 = -1.0;
//   constant Real r8[1] = -1.0;
//   constant Real r8[2] = -2.0;
//   constant Real r8[3] = -3.0;
// end CevalSub1;
// endResult
