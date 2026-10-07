// name:     AlgorithmFor1
// keywords: algorithm,array
// status:   correct
//
// Test for loops in algorithms.
//

class AlgorithmFor1
  Real a[5];
algorithm
  a[1] := 1.0;
  for i in {2,3,4,5} loop
    a[i] := a[i-1] + 1.0;
  end for;
end AlgorithmFor1;

// Result:
// class AlgorithmFor1
//   Real a[1];
//   Real a[2];
//   Real a[3];
//   Real a[4];
//   Real a[5];
// algorithm
//   a[1] := 1.0;
//   for i in {2, 3, 4, 5} loop
//     a[i] := a[i - 1] + 1.0;
//   end for;
// end AlgorithmFor1;
// [flattening/modelica/algorithms-functions/AlgorithmFor1.mo:9:3-9:12:writable] Warning: Components are deprecated in class.
// [flattening/modelica/algorithms-functions/AlgorithmFor1.mo:11:3-11:14:writable] Warning: Algorithm sections are deprecated in class.
//
// endResult
