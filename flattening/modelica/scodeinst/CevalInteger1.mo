// name: CevalInteger1
// keywords:
// status: correct
// cflags: -d=newInst
//
//

model CevalInteger1
  constant Integer i1 = integer(3.4);
end CevalInteger1;

// Result:
// class CevalInteger1
//   constant Integer i1 = 3;
// end CevalInteger1;
// endResult
