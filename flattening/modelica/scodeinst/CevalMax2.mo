// name: CevalMax2
// keywords:
// status: correct
// cflags: -d=newInst
//
//

model CevalMax2
  constant Real r1 = 1.0;
  constant Real r2 = 2.0;
  constant Real r3 = 3.0;
  constant Real r4 = max({r1, r2, r3, r2});
  constant Real r5 = max({{r1, r2, r3, r2}, {5.0, 4.0, 2.0, 5.0}});
end CevalMax2;

// Result:
// class CevalMax2
//   constant Real r1 = 1.0;
//   constant Real r2 = 2.0;
//   constant Real r3 = 3.0;
//   constant Real r4 = 3.0;
//   constant Real r5 = 5.0;
// end CevalMax2;
// endResult
