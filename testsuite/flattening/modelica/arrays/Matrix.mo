// name:     Matrix
// keywords: array, matrix
// status:   correct
//
// Tests the matrix dimensionality conversion function.
//

model Matrix
  Real r1[:,:] = matrix(2.0);
  Real r2[:,:] = matrix({1, 2, 3});
  Real r3[:,:] = matrix([1, 2, 3; 4, 5, 6; 7, 8, 9]);
  Real r4[:,:] = matrix([{1},{2},{3};{4},{5},{6}]);
  Real r5[:,:] = matrix([{{1}},{{2}},{{3}};{{4}},{{5}},{{6}}]);
end Matrix;

// Result:
// class Matrix
//   Real r1[1,1];
//   Real r2[1,1];
//   Real r2[2,1];
//   Real r2[3,1];
//   Real r3[1,1];
//   Real r3[1,2];
//   Real r3[1,3];
//   Real r3[2,1];
//   Real r3[2,2];
//   Real r3[2,3];
//   Real r3[3,1];
//   Real r3[3,2];
//   Real r3[3,3];
//   Real r4[1,1];
//   Real r4[1,2];
//   Real r4[1,3];
//   Real r4[2,1];
//   Real r4[2,2];
//   Real r4[2,3];
//   Real r5[1,1];
//   Real r5[1,2];
//   Real r5[1,3];
//   Real r5[2,1];
//   Real r5[2,2];
//   Real r5[2,3];
// equation
//   r1 = {{2.0}};
//   r2 = {{1.0}, {2.0}, {3.0}};
//   r3 = {{1.0, 2.0, 3.0}, {4.0, 5.0, 6.0}, {7.0, 8.0, 9.0}};
//   r4 = {{1.0, 2.0, 3.0}, {4.0, 5.0, 6.0}};
//   r5 = {{1.0, 2.0, 3.0}, {4.0, 5.0, 6.0}};
// end Matrix;
// endResult
