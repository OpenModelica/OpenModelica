// name: CevalMod1
// keywords:
// status: correct
// cflags: -d=newInst
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
//   constant Real r1 = 0.2000000000000002;
//   constant Real r2 = 1.199999999999999;
//   constant Real r3 = -1.199999999999999;
//   constant Integer i1 = 1;
// end CevalMod1;
// endResult
