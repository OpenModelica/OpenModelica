// name: CevalSqrt1
// keywords:
// status: correct
// cflags: -d=newInst
//
//

model CevalSqrt1
  constant Real r1 = sqrt(4);
  constant Real r2 = sqrt(5.3);
end CevalSqrt1;

// Result:
// class CevalSqrt1
//   constant Real r1 = 2.0;
//   constant Real r2 = 2.302172886644267;
// end CevalSqrt1;
// endResult
