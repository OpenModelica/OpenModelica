// name: CevalDiv1
// keywords:
// status: correct
// cflags: -d=newInst
//
//

model CevalDiv1
  constant Integer i1 = div(10, 3);
  constant Integer i2 = div(-10, 3);
  constant Real r1 = div(10.0, 3.0);
  constant Real r2 = div(-10.0, 3.0);
  constant Real r3 = div(10, 3.0);
end CevalDiv1;

// Result:
// class CevalDiv1
//   constant Integer i1 = 3;
//   constant Integer i2 = -3;
//   constant Real r1 = 3.0;
//   constant Real r2 = -3.0;
//   constant Real r3 = 3.0;
// end CevalDiv1;
// endResult
