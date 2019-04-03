// name: CevalTranspose1
// keywords:
// status: correct
// cflags: -d=newInst
//
//

model CevalTranspose1
  constant Integer i1[:, :] = transpose({{1, 2, 3}, {4, 5, 6}, {7, 8, 9}});
end CevalTranspose1;

// Result:
// class CevalTranspose1
//   constant Integer i1[1,1] = 1;
//   constant Integer i1[1,2] = 4;
//   constant Integer i1[1,3] = 7;
//   constant Integer i1[2,1] = 2;
//   constant Integer i1[2,2] = 5;
//   constant Integer i1[2,3] = 8;
//   constant Integer i1[3,1] = 3;
//   constant Integer i1[3,2] = 6;
//   constant Integer i1[3,3] = 9;
// end CevalTranspose1;
// endResult
