// name:     AlgorithmFor4
// keywords: algorithm,array
// status:   correct
//
// Test for loops in algorithms.
//

class AlgorithmFor4
  Real a[4];
algorithm
  for i in 1:2:3 loop
    a[i+1] := a[i] + 1.0;
  end for;
end AlgorithmFor4;

// Result:
// class AlgorithmFor4
//   Real a[1];
//   Real a[2];
//   Real a[3];
//   Real a[4];
// algorithm
//   for i in 1:2:3 loop
//     a[i + 1] := a[i] + 1.0;
//   end for;
// end AlgorithmFor4;
// [flattening/modelica/algorithms-functions/AlgorithmFor4.mo:9:3-9:12:writable] Warning: Components are deprecated in class.
// [flattening/modelica/algorithms-functions/AlgorithmFor4.mo:11:3-13:10:writable] Warning: Algorithm sections are deprecated in class.
//
// endResult
