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
//   parameter Integer N = 4;
//   Real a[1];
//   Real a[2];
//   Real a[3];
//   Real a[4];
// algorithm
//   a[1] := 1.0;
//   for i in 1:-1 + N loop
//     a[1 + i] := 1.0 + a[i];
//   end for;
// end AlgorithmFor3;
// endResult
