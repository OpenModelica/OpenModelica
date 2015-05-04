// name: MatrixBrackets
// keywords: array, matrix
// status: correct
//
// Tests matrix construction with [] syntax
//

model MatrixBrackets
  Integer intMatrix[4,4];
equation
  intMatrix = [1,2,3,4; 5,6,7,8; 8,7,6,5; 4,3,2,1];
end MatrixBrackets;

// Result:
// class MatrixBrackets
//   Integer intMatrix[1,1];
//   Integer intMatrix[1,2];
//   Integer intMatrix[1,3];
//   Integer intMatrix[1,4];
//   Integer intMatrix[2,1];
//   Integer intMatrix[2,2];
//   Integer intMatrix[2,3];
//   Integer intMatrix[2,4];
//   Integer intMatrix[3,1];
//   Integer intMatrix[3,2];
//   Integer intMatrix[3,3];
//   Integer intMatrix[3,4];
//   Integer intMatrix[4,1];
//   Integer intMatrix[4,2];
//   Integer intMatrix[4,3];
//   Integer intMatrix[4,4];
// equation
//   intMatrix[1,1] = 1;
//   intMatrix[1,2] = 2;
//   intMatrix[1,3] = 3;
//   intMatrix[1,4] = 4;
//   intMatrix[2,1] = 5;
//   intMatrix[2,2] = 6;
//   intMatrix[2,3] = 7;
//   intMatrix[2,4] = 8;
//   intMatrix[3,1] = 8;
//   intMatrix[3,2] = 7;
//   intMatrix[3,3] = 6;
//   intMatrix[3,4] = 5;
//   intMatrix[4,1] = 4;
//   intMatrix[4,2] = 3;
//   intMatrix[4,3] = 2;
//   intMatrix[4,4] = 1;
// end MatrixBrackets;
// endResult
