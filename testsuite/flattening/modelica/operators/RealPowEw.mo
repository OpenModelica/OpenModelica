// name: RealPowEw
// keywords: real, power, element-wise
// status: correct
//
// Tests the element-wise power operator.
//

model RealPowEw
  Real x1[3], x2[3];
  Real x3[2, 2], x4[2, 2];
  Real x5[2, 2, 2], x6[2, 2, 2];
  Real y1[3];
  Real y2[2, 2];
  Real y3[2, 2, 2];
equation
  y1 = x1 .^ x2;
  y2 = x3 .^ x4;
  y3 = x5 .^ x6;
end RealPowEw;

// Result:
// class RealPowEw
//   Real x1[1];
//   Real x1[2];
//   Real x1[3];
//   Real x2[1];
//   Real x2[2];
//   Real x2[3];
//   Real x3[1,1];
//   Real x3[1,2];
//   Real x3[2,1];
//   Real x3[2,2];
//   Real x4[1,1];
//   Real x4[1,2];
//   Real x4[2,1];
//   Real x4[2,2];
//   Real x5[1,1,1];
//   Real x5[1,1,2];
//   Real x5[1,2,1];
//   Real x5[1,2,2];
//   Real x5[2,1,1];
//   Real x5[2,1,2];
//   Real x5[2,2,1];
//   Real x5[2,2,2];
//   Real x6[1,1,1];
//   Real x6[1,1,2];
//   Real x6[1,2,1];
//   Real x6[1,2,2];
//   Real x6[2,1,1];
//   Real x6[2,1,2];
//   Real x6[2,2,1];
//   Real x6[2,2,2];
//   Real y1[1];
//   Real y1[2];
//   Real y1[3];
//   Real y2[1,1];
//   Real y2[1,2];
//   Real y2[2,1];
//   Real y2[2,2];
//   Real y3[1,1,1];
//   Real y3[1,1,2];
//   Real y3[1,2,1];
//   Real y3[1,2,2];
//   Real y3[2,1,1];
//   Real y3[2,1,2];
//   Real y3[2,2,1];
//   Real y3[2,2,2];
// equation
//   y1[1] = x1[1] ^ x2[1];
//   y1[2] = x1[2] ^ x2[2];
//   y1[3] = x1[3] ^ x2[3];
//   y2[1,1] = x3[1,1] ^ x4[1,1];
//   y2[1,2] = x3[1,2] ^ x4[1,2];
//   y2[2,1] = x3[2,1] ^ x4[2,1];
//   y2[2,2] = x3[2,2] ^ x4[2,2];
//   y3[1,1,1] = x5[1,1,1] ^ x6[1,1,1];
//   y3[1,1,2] = x5[1,1,2] ^ x6[1,1,2];
//   y3[1,2,1] = x5[1,2,1] ^ x6[1,2,1];
//   y3[1,2,2] = x5[1,2,2] ^ x6[1,2,2];
//   y3[2,1,1] = x5[2,1,1] ^ x6[2,1,1];
//   y3[2,1,2] = x5[2,1,2] ^ x6[2,1,2];
//   y3[2,2,1] = x5[2,2,1] ^ x6[2,2,1];
//   y3[2,2,2] = x5[2,2,2] ^ x6[2,2,2];
// end RealPowEw;
// endResult
