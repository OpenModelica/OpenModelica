// name: CevalCos1
// keywords:
// status: correct
// cflags: -d=newInst
//
//

model CevalCos1
  constant Real r1 = cos(1);
end CevalCos1;

// Result:
// class CevalCos1
//   constant Real r1 = 0.5403023058681398;
// end CevalCos1;
// endResult
