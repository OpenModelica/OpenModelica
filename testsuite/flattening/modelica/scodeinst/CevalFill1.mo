// name: CevalFill1
// keywords:
// status: correct
// cflags: -d=newInst
//
//

model CevalFill1
  constant Real r1[2, 4, 3] = fill(4.0, 2, 4, 3);
end CevalFill1;

// Result:
// class CevalFill1
//   constant Real r1[1,1,1] = 4.0;
//   constant Real r1[1,1,2] = 4.0;
//   constant Real r1[1,1,3] = 4.0;
//   constant Real r1[1,2,1] = 4.0;
//   constant Real r1[1,2,2] = 4.0;
//   constant Real r1[1,2,3] = 4.0;
//   constant Real r1[1,3,1] = 4.0;
//   constant Real r1[1,3,2] = 4.0;
//   constant Real r1[1,3,3] = 4.0;
//   constant Real r1[1,4,1] = 4.0;
//   constant Real r1[1,4,2] = 4.0;
//   constant Real r1[1,4,3] = 4.0;
//   constant Real r1[2,1,1] = 4.0;
//   constant Real r1[2,1,2] = 4.0;
//   constant Real r1[2,1,3] = 4.0;
//   constant Real r1[2,2,1] = 4.0;
//   constant Real r1[2,2,2] = 4.0;
//   constant Real r1[2,2,3] = 4.0;
//   constant Real r1[2,3,1] = 4.0;
//   constant Real r1[2,3,2] = 4.0;
//   constant Real r1[2,3,3] = 4.0;
//   constant Real r1[2,4,1] = 4.0;
//   constant Real r1[2,4,2] = 4.0;
//   constant Real r1[2,4,3] = 4.0;
// end CevalFill1;
// endResult
