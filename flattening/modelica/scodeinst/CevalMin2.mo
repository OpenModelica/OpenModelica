// name: CevalMin2
// keywords:
// status: correct
// cflags: -d=newInst
//
//

model CevalMin2
  constant Real r1 = 1.0;
  constant Real r2 = 2.0;
  constant Real r3 = 3.0;
  constant Real r4 = min({r1, r2, r3, r2});
  constant Real r5 = min({{r1, r2, r3, r2}, {5.0, 4.0, 2.0, 5.0}});
end CevalMin2;

// Result:
// class CevalMin2
//   constant Real r1 = 1.0;
//   constant Real r2 = 2.0;
//   constant Real r3 = 3.0;
//   constant Real r4 = 1.0;
//   constant Real r5 = 1.0;
// end CevalMin2;
// endResult
