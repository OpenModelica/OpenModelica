// name: ImplicitRangeAlg2
// keywords:
// status: correct
//
//

function f
  input Real x[:];
  output Real sum = 0.0;
algorithm
  for i loop
    sum := sum + x[i];
  end for;
end f;

model ImplicitRangeAlg2
  Real x = f({1, 2, 3});
end ImplicitRangeAlg2;

// Result:
// class ImplicitRangeAlg2
//   Real x = 6.0;
// end ImplicitRangeAlg2;
// endResult
