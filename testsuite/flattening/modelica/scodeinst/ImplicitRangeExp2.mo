// name: ImplicitRangeExp2
// keywords:
// status: correct
//
//

model ImplicitRangeExp2
  Real x[3];
  Real y = sum(x[i] for i);
end ImplicitRangeExp2;

// Result:
// class ImplicitRangeExp2
//   Real x[1];
//   Real x[2];
//   Real x[3];
//   Real y = x[1] + x[2] + x[3];
// end ImplicitRangeExp2;
// endResult
