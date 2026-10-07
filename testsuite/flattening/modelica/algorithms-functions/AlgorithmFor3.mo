// name:     AlgorithmFor3
// keywords: algorithm,array
// status:   correct
//
// Test for loops in algorithms. The size is a parameter.
//

class AlgorithmFor3
  parameter Integer N = 4;
  Real a[N];
algorithm
  a[1] := 1.0;
  for i in 1:N-1 loop
    a[i+1] := a[i] + 1.0;
  end for;
end AlgorithmFor3;

// Result:
// class AlgorithmFor3
//   final parameter Integer N = 4;
//   Real a[1];
//   Real a[2];
//   Real a[3];
//   Real a[4];
// algorithm
//   a[1] := 1.0;
//   for i in 1:3 loop
//     a[i + 1] := a[i] + 1.0;
//   end for;
// end AlgorithmFor3;
// [flattening/modelica/algorithms-functions/AlgorithmFor3.mo:9:3-9:26:writable] Warning: Components are deprecated in class.
// [flattening/modelica/algorithms-functions/AlgorithmFor3.mo:10:3-10:12:writable] Warning: Components are deprecated in class.
// [flattening/modelica/algorithms-functions/AlgorithmFor3.mo:12:3-12:14:writable] Warning: Algorithm sections are deprecated in class.
//
// endResult
