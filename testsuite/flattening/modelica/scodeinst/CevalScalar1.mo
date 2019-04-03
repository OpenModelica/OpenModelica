// name: CevalScalar1
// keywords:
// status: correct
// cflags: -d=newInst
//
//

model CevalScalar1
  constant Real r1 = scalar({{{1.0}}});
  constant Real r2 = scalar(4.0);
end CevalScalar1;

// Result:
// class CevalScalar1
//   constant Real r1 = 1.0;
//   constant Real r2 = 4.0;
// end CevalScalar1;
// endResult
