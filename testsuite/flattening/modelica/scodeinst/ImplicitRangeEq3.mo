// name: ImplicitRangeEq3
// keywords:
// status: correct
//
//

model ImplicitRangeEq3
  Real x[3, 2];
  Real y[3];
equation
  for i loop
    x[i] = {y[i], y[i]};
  end for;
end ImplicitRangeEq3;

// Result:
// class ImplicitRangeEq3
//   Real x[1,1];
//   Real x[1,2];
//   Real x[2,1];
//   Real x[2,2];
//   Real x[3,1];
//   Real x[3,2];
//   Real y[1];
//   Real y[2];
//   Real y[3];
// equation
//   x[1,1] = y[1];
//   x[1,2] = y[1];
//   x[2,1] = y[2];
//   x[2,2] = y[2];
//   x[3,1] = y[3];
//   x[3,2] = y[3];
// end ImplicitRangeEq3;
// endResult
