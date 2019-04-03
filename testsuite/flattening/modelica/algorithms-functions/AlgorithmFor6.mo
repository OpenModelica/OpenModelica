// name:     AlgorithmFor6
// keywords: algorithm,array
// status:   correct
//
// Test for multiple loops in algorithms.
//

class AlgorithmFor6
  Real a[2,3];
algorithm
  for i, j in {2,3} loop
    a[i,j] := i + j;
  end for;
end AlgorithmFor6;

// Result:
// class AlgorithmFor6
//   Real a[1,1];
//   Real a[1,2];
//   Real a[1,3];
//   Real a[2,1];
//   Real a[2,2];
//   Real a[2,3];
// algorithm
//   for i in 1:2 loop
//     for j in {2, 3} loop
//       a[i,j] := /*Real*/(i + j);
//     end for;
//   end for;
// end AlgorithmFor6;
// endResult
