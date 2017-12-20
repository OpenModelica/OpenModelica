// name: CevalDiagonal1
// keywords:
// status: correct
// cflags: -d=newInst
//
//

model CevalDiagonal1
  constant Real r1[4, 4] = diagonal({1, 2, 3, 4});
end CevalDiagonal1;

// Result:
// class CevalDiagonal1
//   constant Real r1[1,1] = 1;
//   constant Real r1[1,2] = 0;
//   constant Real r1[1,3] = 0;
//   constant Real r1[1,4] = 0;
//   constant Real r1[2,1] = 0;
//   constant Real r1[2,2] = 2;
//   constant Real r1[2,3] = 0;
//   constant Real r1[2,4] = 0;
//   constant Real r1[3,1] = 0;
//   constant Real r1[3,2] = 0;
//   constant Real r1[3,3] = 3;
//   constant Real r1[3,4] = 0;
//   constant Real r1[4,1] = 0;
//   constant Real r1[4,2] = 0;
//   constant Real r1[4,3] = 0;
//   constant Real r1[4,4] = 4;
// end CevalDiagonal1;
// endResult
