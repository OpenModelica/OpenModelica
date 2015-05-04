// name:     BlockMatrix2
// keywords: array
// status:   correct
//
// Drmodelica: 7.5 Array Concatenation and Slice Operations (p. 219)
//

class BlockMatrix2
  Real[3, 3]  P = [ 1, 2, 3;
          4, 5, 6;
          7, 8, 9];
  Real[6, 6]  Q;
equation
  Q[1:3, 1:3] = P;  // Upper left block
  Q[1:3, 4:6] = [Q[1:3, 1:2], -Q[1:3, 3:3]];  // Upper right block
  Q[4:6, 1:3] = [Q[1:2, 1:3]; -Q[3:3, 1:3]];  // Lower left block
  Q[4:6, 4:6] = P;  // Lower right block
end BlockMatrix2;

// Result:
// class BlockMatrix2
//   Real P[1,1];
//   Real P[1,2];
//   Real P[1,3];
//   Real P[2,1];
//   Real P[2,2];
//   Real P[2,3];
//   Real P[3,1];
//   Real P[3,2];
//   Real P[3,3];
//   Real Q[1,1];
//   Real Q[1,2];
//   Real Q[1,3];
//   Real Q[1,4];
//   Real Q[1,5];
//   Real Q[1,6];
//   Real Q[2,1];
//   Real Q[2,2];
//   Real Q[2,3];
//   Real Q[2,4];
//   Real Q[2,5];
//   Real Q[2,6];
//   Real Q[3,1];
//   Real Q[3,2];
//   Real Q[3,3];
//   Real Q[3,4];
//   Real Q[3,5];
//   Real Q[3,6];
//   Real Q[4,1];
//   Real Q[4,2];
//   Real Q[4,3];
//   Real Q[4,4];
//   Real Q[4,5];
//   Real Q[4,6];
//   Real Q[5,1];
//   Real Q[5,2];
//   Real Q[5,3];
//   Real Q[5,4];
//   Real Q[5,5];
//   Real Q[5,6];
//   Real Q[6,1];
//   Real Q[6,2];
//   Real Q[6,3];
//   Real Q[6,4];
//   Real Q[6,5];
//   Real Q[6,6];
// equation
//   P = {{1.0, 2.0, 3.0}, {4.0, 5.0, 6.0}, {7.0, 8.0, 9.0}};
//   Q[1,1] = P[1,1];
//   Q[1,2] = P[1,2];
//   Q[1,3] = P[1,3];
//   Q[2,1] = P[2,1];
//   Q[2,2] = P[2,2];
//   Q[2,3] = P[2,3];
//   Q[3,1] = P[3,1];
//   Q[3,2] = P[3,2];
//   Q[3,3] = P[3,3];
//   Q[1,4] = Q[1,1];
//   Q[1,5] = Q[1,2];
//   Q[1,6] = -Q[1,3];
//   Q[2,4] = Q[2,1];
//   Q[2,5] = Q[2,2];
//   Q[2,6] = -Q[2,3];
//   Q[3,4] = Q[3,1];
//   Q[3,5] = Q[3,2];
//   Q[3,6] = -Q[3,3];
//   Q[4,1] = Q[1,1];
//   Q[4,2] = Q[1,2];
//   Q[4,3] = Q[1,3];
//   Q[5,1] = Q[2,1];
//   Q[5,2] = Q[2,2];
//   Q[5,3] = Q[2,3];
//   Q[6,1] = -Q[3,1];
//   Q[6,2] = -Q[3,2];
//   Q[6,3] = -Q[3,3];
//   Q[4,4] = P[1,1];
//   Q[4,5] = P[1,2];
//   Q[4,6] = P[1,3];
//   Q[5,4] = P[2,1];
//   Q[5,5] = P[2,2];
//   Q[5,6] = P[2,3];
//   Q[6,4] = P[3,1];
//   Q[6,5] = P[3,2];
//   Q[6,6] = P[3,3];
// end BlockMatrix2;
// endResult
