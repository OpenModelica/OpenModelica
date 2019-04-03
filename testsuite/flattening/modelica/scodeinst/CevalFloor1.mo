// name: CevalFloor1
// keywords:
// status: correct
// cflags: -d=newInst
//
//

model CevalFloor1
  constant Real r1 = floor(4.6);
  constant Real r2 = floor(6.2);
  constant Real r3 = floor(-4.9);
end CevalFloor1;

// Result:
// class CevalFloor1
//   constant Real r1 = 4.0;
//   constant Real r2 = 6.0;
//   constant Real r3 = -5.0;
// end CevalFloor1;
// endResult
