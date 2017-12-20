// name: CevalZeros1
// keywords:
// status: correct
// cflags: -d=newInst
//
//

model CevalZeros1
  constant Integer r1[4, 3] = zeros(4, 3);
end CevalZeros1;

// Result:
// class CevalZeros1
//   constant Integer r1[1,1] = 0;
//   constant Integer r1[1,2] = 0;
//   constant Integer r1[1,3] = 0;
//   constant Integer r1[2,1] = 0;
//   constant Integer r1[2,2] = 0;
//   constant Integer r1[2,3] = 0;
//   constant Integer r1[3,1] = 0;
//   constant Integer r1[3,2] = 0;
//   constant Integer r1[3,3] = 0;
//   constant Integer r1[4,1] = 0;
//   constant Integer r1[4,2] = 0;
//   constant Integer r1[4,3] = 0;
// end CevalZeros1;
// endResult
