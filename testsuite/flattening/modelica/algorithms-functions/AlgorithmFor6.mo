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
//       a[i,j] := /*Real*/(i) + /*Real*/(j);
//     end for;
//   end for;
// end AlgorithmFor6;
// [flattening/modelica/algorithms-functions/AlgorithmFor6.mo:9:3-9:14:writable] Warning: Components are deprecated in class.
// [flattening/modelica/algorithms-functions/AlgorithmFor6.mo:11:3-13:10:writable] Warning: Algorithm sections are deprecated in class.
//
// endResult
