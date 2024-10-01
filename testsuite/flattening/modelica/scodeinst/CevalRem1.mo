// name: CevalRem1
// keywords:
// status: correct
//
//

model CevalRem1
  constant Real r1 = rem(3, 1.4);
  constant Real r2 = rem(-3, 1.4);
  constant Integer i1 = rem(10, 3);
end CevalRem1;

// Result:
// class CevalRem1
//   constant Real r1 = 0.20000000000000018;
//   constant Real r2 = -0.20000000000000018;
//   constant Integer i1 = 1;
// end CevalRem1;
// endResult
