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
//   x = /*Real*/(hold(3));
//   y[1] = hold(z[1]);
//   y[2] = hold(z[2]);
// end HoldTest;
// endResult
