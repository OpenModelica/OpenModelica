// name:     ArraySlice
// keywords: array
// status:   incorrect
//
// Drmodelica: 7.4 Array Indexing operator (p. 216)
//
class ArraySlice
  Real x1    = X[2, 1];    // Retrieves the value 3
  Real x2[3] = X[:, 1];    // Gets the first column of X as the vector {1, 3, 8}
  Real x3[2] = X[2, :];    // Gets the second row of X as the vector {3, 4}
  Real x4[2] = X[2, 1:2];  // Same as above, i.e. {3, 4}
  Real x5[2] = X[2, {1, 2}];  // Same as above, i.e. {3, 4}
  Real x6[1] = X[2, {2}];  // Half of the above vector, i.e. {4}
  Real x7[3, 1] = X[:, 1:1];  // Gets the first column of X as
            // column matrix {{1}, {3}, {8}}
  Real x8[1, 2] = X[{2}, :];  // Gets the second row of X as the row matrix {{3, 4}}
  Real x9[2, 2] = X[{2, 3}, {1, 2}]; // Extract submatrix given {{3, 4}, {8, 9}}

  Real w1[3] = w[2:4];    // Get the 2:nd through 4:th elements as {16, 17, 18}
  Real w2[2] = w[{1, 3}];  // Get the 1:st and 3:rd elements as {15, 17}
  Real w3[2] = w[1:2:4];  // Get the 1:st to 4:th step 2 elements as {15, 17}

  Real X[3, 2] = {{1, 2}, {3, 4}, {8, 9}};
  Real w[4]    = {15, 16, 17, 18};
  Real[4] y = fill(1, 4);
algorithm
   w[3:4] := {1, 2};  // Assignment causing w to become {15, 16, 1, 2}
end ArraySlice;
