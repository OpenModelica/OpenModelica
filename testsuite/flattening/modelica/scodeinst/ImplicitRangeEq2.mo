// name: ImplicitRangeEq2
// keywords:
// status: correct
//
//

model ImplicitRangeEq2
  Real x[3];
  Real y[3];
equation
  for i loop
    x[i] = y[i];
  end for;
end ImplicitRangeEq2;

// Result:
// class ImplicitRangeEq2
//   Real x[1];
//   Real x[2];
//   Real x[3];
//   Real y[1];
//   Real y[2];
//   Real y[3];
// equation
//   x[1] = y[1];
//   x[2] = y[2];
//   x[3] = y[3];
// end ImplicitRangeEq2;
// endResult
