// name: CevalAsin1
// keywords:
// status: correct
// cflags: -d=newInst
//
//

model CevalAsin1
  constant Real r1 = asin(0);
end CevalAsin1;

// Result:
// class CevalAsin1
//   constant Real r1 = 0.0;
// end CevalAsin1;
// endResult
