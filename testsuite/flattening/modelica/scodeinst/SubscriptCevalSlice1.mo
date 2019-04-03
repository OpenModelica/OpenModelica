// name: SubscriptCevalSlice1
// keywords:
// status: correct
// cflags: -d=newInst
//

model SubscriptCevalSlice1
  constant Real x[3] = {1, 2, 3};
  Real y[2] = x[2:3];
end SubscriptCevalSlice1;

// Result:
// class SubscriptCevalSlice1
//   constant Real x[1] = 1.0;
//   constant Real x[2] = 2.0;
//   constant Real x[3] = 3.0;
//   Real y[1];
//   Real y[2];
// equation
//   y = {2.0, 3.0};
// end SubscriptCevalSlice1;
// endResult
