// name: SubscriptCevalWhole1
// keywords:
// status: correct
// cflags: -d=newInst
//

model SubscriptCevalWhole1
  constant Real x[3] = {1, 2, 3};
  Real y[3] = x[:];
end SubscriptCevalWhole1;

// Result:
// class SubscriptCevalWhole1
//   constant Real x[1] = 1.0;
//   constant Real x[2] = 2.0;
//   constant Real x[3] = 3.0;
//   Real y[1];
//   Real y[2];
//   Real y[3];
// equation
//   y = {1.0, 2.0, 3.0};
// end SubscriptCevalWhole1;
// endResult
