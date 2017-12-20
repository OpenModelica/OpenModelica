// name: CevalOnes1
// keywords:
// status: correct
// cflags: -d=newInst
//
//

model CevalOnes1
  constant Integer r1[4, 3] = ones(4, 3);
end CevalOnes1;

// Result:
// class CevalOnes1
//   constant Integer r1[1,1] = 1;
//   constant Integer r1[1,2] = 1;
//   constant Integer r1[1,3] = 1;
//   constant Integer r1[2,1] = 1;
//   constant Integer r1[2,2] = 1;
//   constant Integer r1[2,3] = 1;
//   constant Integer r1[3,1] = 1;
//   constant Integer r1[3,2] = 1;
//   constant Integer r1[3,3] = 1;
//   constant Integer r1[4,1] = 1;
//   constant Integer r1[4,2] = 1;
//   constant Integer r1[4,3] = 1;
// end CevalOnes1;
// endResult
