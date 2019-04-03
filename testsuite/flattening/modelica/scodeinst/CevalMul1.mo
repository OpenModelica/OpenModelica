// name: CevalMul1
// keywords:
// status: correct
// cflags: -d=newInst
//

model CevalSub1
  constant Integer i1 = 2 * 2;
  constant Integer i2[:] = {1, 2, 3} .* {3, 4, 5};
  constant Integer i3[:, :] = {{1, 2}, {3, 4}} .* {{5, 6}, {7, 8}};
  constant Integer i4[:] = 2 .* {1, 2, 3};
  constant Integer i5[:] = {1, 2, 3} .* 2;
  constant Integer i6[:] = zeros(0) .* zeros(0);

  constant Real r1 = 2 * 2;
  constant Real r2[:] = {1, 2, 3} .* {3, 4, 5};
  constant Real r3[:, :] = {{1, 2}, {3, 4}} .* {{5, 6}, {7, 8}};
  constant Real r4[:] = 2 .* {1, 2, 3};
  constant Real r5[:] = {1, 2, 3} .* 2;
  constant Integer r6[:] = zeros(0) .* zeros(0);
end CevalSub1;

// Result:
// class CevalSub1
//   constant Integer i1 = 4;
//   constant Integer i2[1] = 3;
//   constant Integer i2[2] = 8;
//   constant Integer i2[3] = 15;
//   constant Integer i3[1,1] = 5;
//   constant Integer i3[1,2] = 12;
//   constant Integer i3[2,1] = 21;
//   constant Integer i3[2,2] = 32;
//   constant Integer i4[1] = 2;
//   constant Integer i4[2] = 4;
//   constant Integer i4[3] = 6;
//   constant Integer i5[1] = 2;
//   constant Integer i5[2] = 4;
//   constant Integer i5[3] = 6;
//   constant Real r1 = 4.0;
//   constant Real r2[1] = 3.0;
//   constant Real r2[2] = 8.0;
//   constant Real r2[3] = 15.0;
//   constant Real r3[1,1] = 5.0;
//   constant Real r3[1,2] = 12.0;
//   constant Real r3[2,1] = 21.0;
//   constant Real r3[2,2] = 32.0;
//   constant Real r4[1] = 2.0;
//   constant Real r4[2] = 4.0;
//   constant Real r4[3] = 6.0;
//   constant Real r5[1] = 2.0;
//   constant Real r5[2] = 4.0;
//   constant Real r5[3] = 6.0;
// end CevalSub1;
// endResult
