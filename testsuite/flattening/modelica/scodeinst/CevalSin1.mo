// name: CevalSin1
// keywords:
// status: correct
// cflags: -d=newInst
//
//

model CevalSin1
  constant Real r1 = sin(1);
end CevalSin1;

// Result:
// class CevalSin1
//   constant Real r1 = 0.8414709848078965;
// end CevalSin1;
// endResult
