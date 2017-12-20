// name: CevalCross1
// keywords:
// status: correct
// cflags: -d=newInst
//
//

model CevalProduct1
  constant Real r1 = product({{{1.0, 2.0}, {3.0, 4.0}}, {{5.0, 6.0}, {7.0, 8.0}}});
  constant Integer i1 = product({1, 2, 3, 4, 5, 6, 7, 8});
end CevalProduct1;

// Result:
// class CevalProduct1
//   constant Real r1 = 40320.0;
//   constant Integer i1 = 40320;
// end CevalProduct1;
// endResult
