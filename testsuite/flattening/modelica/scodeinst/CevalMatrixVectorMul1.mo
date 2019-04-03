// name: CevalVectorMatrixMul1
// keywords:
// status: correct
// cflags: -d=newInst
//
//

model CevalMatrixVectorMul1
  constant Real m1[3, 3] = {{1, 2, 3}, {4, 5, 6}, {7, 8, 9}};
  constant Real v1[3] = {3, 6, 9};
  constant Real m2[:] = m1 * v1;
end CevalMatrixVectorMul1;

// Result:
// class CevalMatrixVectorMul1
//   constant Real m1[1,1] = 1.0;
//   constant Real m1[1,2] = 2.0;
//   constant Real m1[1,3] = 3.0;
//   constant Real m1[2,1] = 4.0;
//   constant Real m1[2,2] = 5.0;
//   constant Real m1[2,3] = 6.0;
//   constant Real m1[3,1] = 7.0;
//   constant Real m1[3,2] = 8.0;
//   constant Real m1[3,3] = 9.0;
//   constant Real v1[1] = 3.0;
//   constant Real v1[2] = 6.0;
//   constant Real v1[3] = 9.0;
//   constant Real m2[1] = 42.0;
//   constant Real m2[2] = 96.0;
//   constant Real m2[3] = 150.0;
// end CevalMatrixVectorMul1;
// endResult
