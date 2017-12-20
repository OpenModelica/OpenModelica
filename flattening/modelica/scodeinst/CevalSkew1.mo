// name: CevalSkew1
// keywords:
// status: correct
// cflags: -d=newInst
//
//

model CevalSkew1
  constant Real r1[:, :] = skew({1, 2, 3});
end CevalSkew1;

// Result:
// class CevalSkew1
//   constant Real r1[1,1] = 0.0;
//   constant Real r1[1,2] = -3.0;
//   constant Real r1[1,3] = 2.0;
//   constant Real r1[2,1] = 3.0;
//   constant Real r1[2,2] = 0.0;
//   constant Real r1[2,3] = -1.0;
//   constant Real r1[3,1] = -2.0;
//   constant Real r1[3,2] = 1.0;
//   constant Real r1[3,3] = 0.0;
// end CevalSkew1;
// endResult
