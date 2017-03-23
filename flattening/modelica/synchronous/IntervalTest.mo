// name: IntervalTest
// keywords: synchronous features
// status: correct

model IntervalTest
  Real y[2], u[2];
  Integer x(start=0);
equation
  x = previous(x);
  y = interval(u);
end IntervalTest;

// Result:
// class IntervalTest
//   Real y[1];
//   Real y[2];
//   Real u[1];
//   Real u[2];
//   Integer x(start = 0);
// equation
//   x = previous(x);
//   y[1] = interval(u[1]);
//   y[2] = interval(u[2]);
// end IntervalTest;
// endResult
