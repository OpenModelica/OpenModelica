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
//     a[1 + i] := 1.0 + a[i];
//   end for;
// end AlgorithmFor2;
// endResult
