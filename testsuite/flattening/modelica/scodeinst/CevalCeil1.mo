// name: CevalCeil1
// keywords:
// status: correct
// cflags: -d=newInst
//
//

model CevalCeil1
  constant Real r1 = ceil(4.6);
  constant Real r2 = ceil(6.2);
  constant Real r3 = ceil(-4.9);
end CevalCeil1;

// Result:
// class CevalCeil1
//   constant Real r1 = 5.0;
//   constant Real r2 = 7.0;
//   constant Real r3 = -4.0;
// end CevalCeil1;
// endResult
