// name:     EmptyArrayAlgorithm.mo [BUG: #2300]
// keywords: Empty arrays used in algorithm
// status:   correct
//
// Empty arrays used in algorithm
//

model EmptyArrayAlgorithm
  parameter Integer N = 0;
  Real r1[N];
  Real r2[N];
equation
  r1 = fill(1.0, N);
algorithm
  r2 := r1;
end EmptyArrayAlgorithm;


// Result:
// class EmptyArrayAlgorithm
//   parameter Integer N = 0;
// algorithm
// end EmptyArrayAlgorithm;
// endResult
