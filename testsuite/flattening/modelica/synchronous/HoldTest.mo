// name: HoldTest
// keywords: synchronous features
// status: correct

model HoldTest
  output Real x;
  output Real y[2];
  Real z[2];
equation
  x = hold(3);
  y = hold(z);
end HoldTest;

// Result:
// class HoldTest
//   output Real x;
//   output Real y[1];
//   output Real y[2];
//   Real z[1];
//   Real z[2];
// equation
//   x = 3.0;
//   y = hold(z);
// end HoldTest;
// endResult
