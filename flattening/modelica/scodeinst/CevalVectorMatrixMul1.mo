// name: CevalVectorMatrixMul1
// keywords:
// status: correct
// cflags: -d=newInst
//
//

model CevalVectorMatrixMul1
  constant Real m1[3, 3] = {{1, 2, 3}, {4, 5, 6}, {7, 8, 9}};
  constant Real v1[3] = {3, 6, 9};
  constant Real m2[:] = v1 * m1;
end CevalVectorMatrixMul1;

// Result:
// class CevalVectorMatrixMul1
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
//   constant Real m2[1] = 90.0;
//   constant Real m2[2] = 108.0;
//   constant Real m2[3] = 126.0;
// end CevalVectorMatrixMul1;
// endResult
