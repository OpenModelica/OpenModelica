// name: CevalCross1
// keywords:
// status: correct
// cflags: -d=newInst
//
//

model CevalCross1
  constant Real r1[:] = cross({1, 2, 3}, {4, 5, 6});
end CevalCross1;

// Result:
// class CevalCross1
//   constant Real r1[1] = -3.0;
//   constant Real r1[2] = 6.0;
//   constant Real r1[3] = -3.0;
// end CevalCross1;
// endResult
