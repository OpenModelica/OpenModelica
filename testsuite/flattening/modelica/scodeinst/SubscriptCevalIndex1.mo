// name: SubscriptCevalIndex1
// keywords:
// status: correct
// cflags: -d=newInst
//

model SubscriptCevalIndex1
  constant Real x[3] = {1, 2, 3};
  Real y = x[2];
end SubscriptCevalIndex1;

// Result:
// class SubscriptCevalIndex1
//   constant Real x[1] = 1.0;
//   constant Real x[2] = 2.0;
//   constant Real x[3] = 3.0;
//   Real y = 2.0;
// end SubscriptCevalIndex1;
// endResult
