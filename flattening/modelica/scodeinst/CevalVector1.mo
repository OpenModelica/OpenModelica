// name: CevalVector1
// keywords:
// status: correct
// cflags: -d=newInst
//
//

model CevalVector1
  constant Integer i1[:] = vector({{{{1}}, {{2}}, {{3}}}});
  constant Integer i2[:] = vector({1, 2, 3});
  constant Integer i3[:] = vector(1);
end CevalVector1;

// Result:
// class CevalVector1
//   constant Integer i1[1] = 1;
//   constant Integer i1[2] = 2;
//   constant Integer i1[3] = 3;
//   constant Integer i2[1] = 1;
//   constant Integer i2[2] = 2;
//   constant Integer i2[3] = 3;
//   constant Integer i3[1] = 1;
// end CevalVector1;
// endResult
