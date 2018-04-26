// name: CevalMatrixProduct1
// keywords:
// status: correct
// cflags: -d=newInst
//
//

model CevalMatrixProduct1
  constant Real m1[3, 3] = {{1, 2, 3}, {4, 5, 6}, {7, 8, 9}};
  constant Real m2[2, 3] = {{6, 5, 4}, {3, 2, 1}};
  constant Real r1[3, 3] = m1 * m1;
  constant Real r3[2, 3] = m2 * m1;
  constant Real y[:, :] = ones(3, 0) * ones(0, 3);
  constant Real z[:, :] = ones(0, 3) * ones(3, 0);
end CevalMatrixProduct1;

// Result:
// class CevalMatrixProduct1
//   constant Real m1[1,1] = 1.0;
//   constant Real m1[1,2] = 2.0;
//   constant Real m1[1,3] = 3.0;
//   constant Real m1[2,1] = 4.0;
//   constant Real m1[2,2] = 5.0;
//   constant Real m1[2,3] = 6.0;
//   constant Real m1[3,1] = 7.0;
//   constant Real m1[3,2] = 8.0;
//   constant Real m1[3,3] = 9.0;
//   constant Real m2[1,1] = 6.0;
//   constant Real m2[1,2] = 5.0;
//   constant Real m2[1,3] = 4.0;
//   constant Real m2[2,1] = 3.0;
//   constant Real m2[2,2] = 2.0;
//   constant Real m2[2,3] = 1.0;
//   constant Real r1[1,1] = 30.0;
//   constant Real r1[1,2] = 36.0;
//   constant Real r1[1,3] = 42.0;
//   constant Real r1[2,1] = 66.0;
//   constant Real r1[2,2] = 81.0;
//   constant Real r1[2,3] = 96.0;
//   constant Real r1[3,1] = 102.0;
//   constant Real r1[3,2] = 126.0;
//   constant Real r1[3,3] = 150.0;
//   constant Real r3[1,1] = 54.0;
//   constant Real r3[1,2] = 69.0;
//   constant Real r3[1,3] = 84.0;
//   constant Real r3[2,1] = 18.0;
//   constant Real r3[2,2] = 24.0;
//   constant Real r3[2,3] = 30.0;
//   constant Real y[1,1] = 0.0;
//   constant Real y[1,2] = 0.0;
//   constant Real y[1,3] = 0.0;
//   constant Real y[2,1] = 0.0;
//   constant Real y[2,2] = 0.0;
//   constant Real y[2,3] = 0.0;
//   constant Real y[3,1] = 0.0;
//   constant Real y[3,2] = 0.0;
//   constant Real y[3,3] = 0.0;
// end CevalMatrixProduct1;
// endResult
