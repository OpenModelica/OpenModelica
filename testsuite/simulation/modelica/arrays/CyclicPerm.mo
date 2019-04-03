// name:     CyclicPerm
// keywords: array
// status:   incorrect
//
// Drmodelica: 7.5 Array Concatenation and Slice Operations (p. 219)
//
class CyclicPerm
  Real[1, 3] WO = [1, 2, 3];          // Row matrix
  Real[2, 3] XO = [1, 2, 3; 4, 5, 6];      // Matrix with two rows

  Real[1, 3] W;                  // Permuted row matrix
  Real[2, 3] X;                  // Permuted matrix with two rows

  Integer[3] p = {2, 3, 1};            // Permutation vector

algorithm
  W := [[2, 3], 1];                // OK, result: [2, 3, 1] = {{2, 3, 1}}
  W := [{{2, 3}}, {{1}}];            // OK, same result: {{2, 3, 1}}

  W := [WO[{1}, 2:3], WO[{1}, {1}]];      // OK, result: {{2, 3, 1}}
  W := [WO[1:1, 2:3], WO[1:1, 1:1]];      // OK, same result: {{2, 3, 1}}

  W := WO[:, p];                // OK, same result: {{2, 3, 1}}

  W := cat(2, WO[1:1, 2:3], WO[1:1, 1:1]); // OK, same result: {{2, 3, 1}}
  W := [WO[1, 2:3], WO[1, 1]];       // Error, since WO[1, 2:3] is a vector

  X := [XO[:, 2:3], XO[:, {1}]];   // OK, X becomes [2, 3, 1; 5, 6, 4]
  X := XO[:, p];                   // OK, X becomes [2, 3, 1; 5, 6, 4]

  X[{1},:] := [XO[{1}, 2:3], XO[{1}, {1}]];  // OK, X becomes [2,3,1; 5,6,4]
  X[1, :] := [XO[1, 2:3], XO[1, 1]];      // ERROR, incompatible dimensions
end CyclicPerm;

