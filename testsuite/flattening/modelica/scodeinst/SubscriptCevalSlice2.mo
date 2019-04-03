// name: SubscriptCevalSlice2
// keywords:
// status: correct
// cflags: -d=newInst
//

model SubscriptCevalSlice2
  constant Real x[5] = {1, 2, 3, 4, 5};
  Real y[3] = x[{5, 1, 3}];
end SubscriptCevalSlice2;

// Result:
// class SubscriptCevalSlice2
//   constant Real x[1] = 1.0;
//   constant Real x[2] = 2.0;
//   constant Real x[3] = 3.0;
//   constant Real x[4] = 4.0;
//   constant Real x[5] = 5.0;
//   Real y[1];
//   Real y[2];
//   Real y[3];
// equation
//   y = {5.0, 1.0, 3.0};
// end SubscriptCevalSlice2;
// endResult
