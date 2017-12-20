// name: CevalAbs1
// keywords:
// status: correct
// cflags: -d=newInst
//
//

model CevalAbs1
  constant Real r1 = abs(-2.0);
  constant Integer i1 = abs(-6);
end CevalAbs1;

// Result:
// class CevalAbs1
//   constant Real r1 = 2.0;
//   constant Integer i1 = 6;
// end CevalAbs1;
// endResult
