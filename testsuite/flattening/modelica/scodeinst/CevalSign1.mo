// name: CevalSign1
// keywords:
// status: correct
// cflags: -d=newInst
//
//

model CevalSign1
  constant Integer i1 = sign(3);
  constant Integer i2 = sign(0);
  constant Integer i3 = sign(-3);
end CevalSign1;

// Result:
// class CevalSign1
//   constant Integer i1 = 1;
//   constant Integer i2 = 0;
//   constant Integer i3 = -1;
// end CevalSign1;
// endResult
