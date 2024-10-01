// name: CevalMod1
// keywords:
// status: correct
//
//

model CevalMod1
  constant Real r1 = mod(3, 1.4);
  constant Real r2 = mod(-3, 1.4);
  constant Real r3 = mod(3, -1.4);
  constant Integer i1 = mod(10, 3);
end CevalMod1;

// Result:
// class CevalMod1
//   constant Real r1 = 0.20000000000000018;
//   constant Real r2 = 1.1999999999999993;
//   constant Real r3 = -1.1999999999999993;
//   constant Integer i1 = 1;
// end CevalMod1;
// endResult
