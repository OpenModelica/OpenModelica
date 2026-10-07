// name:     AlgorithmFor2
// keywords: algorithm,array
// status:   correct
//
// Test for loops in algorithms. The size is a constant.
//

class AlgorithmFor2
  constant Integer N = 4;
  Real a[N];
algorithm
  a[1] := 1.0;
  for i in 1:N-1 loop
    a[i+1] := a[i] + 1.0;
  end for;
end AlgorithmFor2;

// Result:
// class AlgorithmFor2
//   constant Integer N = 4;
//   Real a[1];
//   Real a[2];
//   Real a[3];
//   Real a[4];
// algorithm
//   a[1] := 1.0;
//   for i in 1:3 loop
//     a[i + 1] := a[i] + 1.0;
//   end for;
// end AlgorithmFor2;
// [flattening/modelica/algorithms-functions/AlgorithmFor2.mo:9:3-9:25:writable] Warning: Components are deprecated in class.
// [flattening/modelica/algorithms-functions/AlgorithmFor2.mo:10:3-10:12:writable] Warning: Components are deprecated in class.
// [flattening/modelica/algorithms-functions/AlgorithmFor2.mo:12:3-12:14:writable] Warning: Algorithm sections are deprecated in class.
//
// endResult
