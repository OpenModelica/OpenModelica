// name: CevalSum1
// keywords:
// status: correct
// cflags: -d=newInst
//
//

model CevalSum1
  constant Real r1 = sum({{{1.0, 2.0}, {3.0, 4.0}}, {{5.0, 6.0}, {7.0, 8.0}}});
  constant Integer i1 = sum({1, 2, 3, 4, 5, 6, 7, 8});
end CevalSum1;

// Result:
// class CevalSum1
//   constant Real r1 = 36.0;
//   constant Integer i1 = 36;
// end CevalSum1;
// endResult
