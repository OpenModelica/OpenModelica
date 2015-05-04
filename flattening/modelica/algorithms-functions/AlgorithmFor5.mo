// name:     AlgorithmFor5
// keywords: algorithm,array
// status:   correct
//
// Test for loops in algorithms. The range is implicit.
//

class AlgorithmFor5
  Real a[4];
algorithm
  for i loop
    a[i] := i;
  end for;
end AlgorithmFor5;

// Result:
// class AlgorithmFor5
//   Real a[1];
//   Real a[2];
//   Real a[3];
//   Real a[4];
// algorithm
//   for i in 1:4 loop
//     a[i] := /*Real*/(i);
//   end for;
// end AlgorithmFor5;
// endResult
