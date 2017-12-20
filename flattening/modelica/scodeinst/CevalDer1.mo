// name: CevalDer1
// keywords:
// status: correct
// cflags: -d=newInst
//
//

model CevalDer1
  constant Real r1 = der(1.0);
  constant Real r2 = der(r1);
end CevalDer1;

// Result:
// class CevalDer1
//   constant Real r1 = 0.0;
//   constant Real r2 = 0.0;
// end CevalDer1;
// endResult
