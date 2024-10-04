// name: ImplicitRangeAlg1
// keywords:
// status: correct
//
//

model ImplicitRangeAlg1
  Real x[3];
  Real y[3];
algorithm
  for i loop
    x[i] := y[i];
  end for;
end ImplicitRangeAlg1;

// Result:
// class ImplicitRangeAlg1
//   Real x[1];
//   Real x[2];
//   Real x[3];
//   Real y[1];
//   Real y[2];
//   Real y[3];
// algorithm
//   for i in 1:3 loop
//     x[i] := y[i];
//   end for;
// end ImplicitRangeAlg1;
// endResult
