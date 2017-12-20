// name: CevalCosh1
// keywords:
// status: correct
// cflags: -d=newInst
//
//

model CevalCosh1
  constant Real r1 = cosh(1);
end CevalCosh1;

// Result:
// class CevalCosh1
//   constant Real r1 = 1.543080634815244;
// end CevalCosh1;
// endResult
