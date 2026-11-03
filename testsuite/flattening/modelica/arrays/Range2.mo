// name:     Range2
// keywords: array bug1825
// status:   correct
//
// Some tests of range expressions with tricky limits due to floating point
// rounding errors.
//

model Range2
  constant Real r1[25] = -2.4 : 0.2 : 2.4;
  constant Real r2[25] = 2.4 : -0.2 : -2.4;
  constant Real r3[5] = 0.0001 : 0.0001 : 0.0005;
  constant Real r4[5] = -0.0002 : 0.0001 : 0.0002;
  constant Real r5[5] = 0.0005 : -0.0001 : 0.0001;
end Range2;

// Result:
// class Range2
//   constant Real r1[1] = -2.4;
//   constant Real r1[2] = -2.1999999999999997;
//   constant Real r1[3] = -2.0;
//   constant Real r1[4] = -1.7999999999999998;
//   constant Real r1[5] = -1.5999999999999999;
//   constant Real r1[6] = -1.4;
//   constant Real r1[7] = -1.1999999999999997;
//   constant Real r1[8] = -0.9999999999999998;
//   constant Real r1[9] = -0.7999999999999998;
//   constant Real r1[10] = -0.5999999999999999;
//   constant Real r1[11] = -0.3999999999999999;
//   constant Real r1[12] = -0.19999999999999973;
//   constant Real r1[13] = 4.440892098500626e-16;
//   constant Real r1[14] = 0.20000000000000018;
//   constant Real r1[15] = 0.40000000000000036;
//   constant Real r1[16] = 0.6000000000000001;
//   constant Real r1[17] = 0.8000000000000003;
//   constant Real r1[18] = 1.0000000000000004;
//   constant Real r1[19] = 1.2000000000000002;
//   constant Real r1[20] = 1.4000000000000004;
//   constant Real r1[21] = 1.6;
//   constant Real r1[22] = 1.8000000000000003;
//   constant Real r1[23] = 2.0000000000000004;
//   constant Real r1[24] = 2.2000000000000006;
//   constant Real r1[25] = 2.4;
//   constant Real r2[1] = 2.4;
//   constant Real r2[2] = 2.1999999999999997;
//   constant Real r2[3] = 2.0;
//   constant Real r2[4] = 1.7999999999999998;
//   constant Real r2[5] = 1.5999999999999999;
//   constant Real r2[6] = 1.4;
//   constant Real r2[7] = 1.1999999999999997;
//   constant Real r2[8] = 0.9999999999999998;
//   constant Real r2[9] = 0.7999999999999998;
//   constant Real r2[10] = 0.5999999999999999;
//   constant Real r2[11] = 0.3999999999999999;
//   constant Real r2[12] = 0.19999999999999973;
//   constant Real r2[13] = -4.440892098500626e-16;
//   constant Real r2[14] = -0.20000000000000018;
//   constant Real r2[15] = -0.40000000000000036;
//   constant Real r2[16] = -0.6000000000000001;
//   constant Real r2[17] = -0.8000000000000003;
//   constant Real r2[18] = -1.0000000000000004;
//   constant Real r2[19] = -1.2000000000000002;
//   constant Real r2[20] = -1.4000000000000004;
//   constant Real r2[21] = -1.6;
//   constant Real r2[22] = -1.8000000000000003;
//   constant Real r2[23] = -2.0000000000000004;
//   constant Real r2[24] = -2.2000000000000006;
//   constant Real r2[25] = -2.4;
//   constant Real r3[1] = 1e-4;
//   constant Real r3[2] = 2e-4;
//   constant Real r3[3] = 3.0000000000000003e-4;
//   constant Real r3[4] = 4e-4;
//   constant Real r3[5] = 5e-4;
//   constant Real r4[1] = -2e-4;
//   constant Real r4[2] = -1e-4;
//   constant Real r4[3] = 0.0;
//   constant Real r4[4] = 1.0000000000000002e-4;
//   constant Real r4[5] = 2e-4;
//   constant Real r5[1] = 5e-4;
//   constant Real r5[2] = 4e-4;
//   constant Real r5[3] = 3.0000000000000003e-4;
//   constant Real r5[4] = 1.9999999999999998e-4;
//   constant Real r5[5] = 1e-4;
// end Range2;
// endResult
