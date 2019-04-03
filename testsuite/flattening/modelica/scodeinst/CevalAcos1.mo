// name: CevalAcos1
// keywords:
// status: correct
// cflags: -d=newInst
//
//

model CevalAcos1
  constant Real r1 = acos(0);
end CevalAcos1;

// Result:
// class CevalAcos1
//   constant Real r1 = 1.570796326794897;
// end CevalAcos1;
// endResult
