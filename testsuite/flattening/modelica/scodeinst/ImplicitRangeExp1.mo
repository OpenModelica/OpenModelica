// name: ImplicitRangeExp1
// keywords:
// status: correct
//
//

model ImplicitRangeExp1
  Real x[3];
  Real y[:] = {x[i] for i};
end ImplicitRangeExp1;

// Result:
// class ImplicitRangeExp1
//   Real x[1];
//   Real x[2];
//   Real x[3];
//   Real y[1];
//   Real y[2];
//   Real y[3];
// equation
//   y = array(x[i] for i in 1:3);
// end ImplicitRangeExp1;
// endResult
