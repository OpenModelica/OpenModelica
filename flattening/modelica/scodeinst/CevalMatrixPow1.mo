// name: CevalMatrixPow1
// keywords:
// status: correct
// cflags: -d=newInst
//
//

model CevalMatrixPow1
  constant Real m1[3, 3] = {{1, 2, 3}, {4, 5, 6}, {7, 8, 9}};
  constant Real r1[:,:] = m1 ^ 0;
  constant Real r2[:,:] = m1 ^ 1;
  constant Real r3[:,:] = m1 ^ 2;
  constant Real r4[:,:] = m1 ^ 3;
  constant Real r5[:,:] = m1 ^ 4;
end CevalMatrixPow1;

// Result:
// class CevalMatrixPow1
//   constant Real m1[1,1] = 1.0;
//   constant Real m1[1,2] = 2.0;
//   constant Real m1[1,3] = 3.0;
//   constant Real m1[2,1] = 4.0;
//   constant Real m1[2,2] = 5.0;
//   constant Real m1[2,3] = 6.0;
//   constant Real m1[3,1] = 7.0;
//   constant Real m1[3,2] = 8.0;
//   constant Real m1[3,3] = 9.0;
//   constant Real r1[1,1] = 1.0;
//   constant Real r1[1,2] = 0.0;
//   constant Real r1[1,3] = 0.0;
//   constant Real r1[2,1] = 0.0;
//   constant Real r1[2,2] = 1.0;
//   constant Real r1[2,3] = 0.0;
//   constant Real r1[3,1] = 0.0;
//   constant Real r1[3,2] = 0.0;
//   constant Real r1[3,3] = 1.0;
//   constant Real r2[1,1] = 1.0;
//   constant Real r2[1,2] = 2.0;
//   constant Real r2[1,3] = 3.0;
//   constant Real r2[2,1] = 4.0;
//   constant Real r2[2,2] = 5.0;
//   constant Real r2[2,3] = 6.0;
//   constant Real r2[3,1] = 7.0;
//   constant Real r2[3,2] = 8.0;
//   constant Real r2[3,3] = 9.0;
//   constant Real r3[1,1] = 30.0;
//   constant Real r3[1,2] = 36.0;
//   constant Real r3[1,3] = 42.0;
//   constant Real r3[2,1] = 66.0;
//   constant Real r3[2,2] = 81.0;
//   constant Real r3[2,3] = 96.0;
//   constant Real r3[3,1] = 102.0;
//   constant Real r3[3,2] = 126.0;
//   constant Real r3[3,3] = 150.0;
//   constant Real r4[1,1] = 468.0;
//   constant Real r4[1,2] = 576.0;
//   constant Real r4[1,3] = 684.0;
//   constant Real r4[2,1] = 1062.0;
//   constant Real r4[2,2] = 1305.0;
//   constant Real r4[2,3] = 1548.0;
//   constant Real r4[3,1] = 1656.0;
//   constant Real r4[3,2] = 2034.0;
//   constant Real r4[3,3] = 2412.0;
//   constant Real r5[1,1] = 7560.0;
//   constant Real r5[1,2] = 9288.0;
//   constant Real r5[1,3] = 11016.0;
//   constant Real r5[2,1] = 17118.0;
//   constant Real r5[2,2] = 21033.0;
//   constant Real r5[2,3] = 24948.0;
//   constant Real r5[3,1] = 26676.0;
//   constant Real r5[3,2] = 32778.0;
//   constant Real r5[3,3] = 38880.0;
// end CevalMatrixPow1;
// endResult
