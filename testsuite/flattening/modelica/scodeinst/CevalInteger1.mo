// name: CevalInteger1
// keywords:
// status: correct
// cflags: -d=newInst
//
//

model CevalInteger1
  constant Integer i1 = integer(3.4);
  constant Integer i2 = integer(4 / 2);
  constant Integer i3 = integer(2);
end CevalInteger1;

// Result:
// class CevalInteger1
//   constant Integer i1 = 3;
//   constant Integer i2 = 2;
//   constant Integer i3 = 2;
// end CevalInteger1;
// endResult
