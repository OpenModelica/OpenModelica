// name: IntervalTest
// keywords: synchronous features
// status: correct

model IntervalTest
  Real y, u[2];
  Integer x(start=0);
equation
  x = previous(x);
  y = interval(u);
end IntervalTest;

// Result:
// class IntervalTest
//   Real y;
//   Real u[1];
//   Real u[2];
//   Integer x(start = 0);
// equation
//   x = previous(x);
//   y = interval({u[1], u[2]});
// end IntervalTest;
// endResult
