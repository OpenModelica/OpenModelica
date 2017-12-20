// name: CevalArray1
// keywords:
// status: correct
// cflags: -d=newInst
//
//

model CevalArray1
  constant Real r1[:] = array(1, 2, 3, 4);
end CevalArray1;

// Result:
// class CevalArray1
//   constant Real r1[1] = 1.0;
//   constant Real r1[2] = 2.0;
//   constant Real r1[3] = 3.0;
//   constant Real r1[4] = 4.0;
// end CevalArray1;
// endResult
