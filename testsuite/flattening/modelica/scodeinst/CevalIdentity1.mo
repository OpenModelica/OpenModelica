// name: CevalIdentity1
// keywords:
// status: correct
// cflags: -d=newInst
//
//

model CevalIdentity1
  constant Integer i1[4, 4] = identity(4);
end CevalIdentity1;

// Result:
// class CevalIdentity1
//   constant Integer i1[1,1] = 1;
//   constant Integer i1[1,2] = 0;
//   constant Integer i1[1,3] = 0;
//   constant Integer i1[1,4] = 0;
//   constant Integer i1[2,1] = 0;
//   constant Integer i1[2,2] = 1;
//   constant Integer i1[2,3] = 0;
//   constant Integer i1[2,4] = 0;
//   constant Integer i1[3,1] = 0;
//   constant Integer i1[3,2] = 0;
//   constant Integer i1[3,3] = 1;
//   constant Integer i1[3,4] = 0;
//   constant Integer i1[4,1] = 0;
//   constant Integer i1[4,2] = 0;
//   constant Integer i1[4,3] = 0;
//   constant Integer i1[4,4] = 1;
// end CevalIdentity1;
// endResult
