// name:     test_02.mo
// keywords: <insert keywords here>
// status:   correct
//
// <insert description here>
//

model simple_test
  Real x(start = -1);
  Real y(start = 1);
  parameter Real lambda = 0.3;
equation
  der(x) = y;
  der(y) = - x + lambda*(1 - x^2)*y;
end simple_test;

// Result:
// class simple_test
//   Real x(start = -1.0);
//   Real y(start = 1.0);
//   parameter Real lambda = 0.3;
// equation
//   der(x) = y;
//   der(y) = lambda * ((1.0 - x ^ 2.0) * y) - x;
// end simple_test;
// endResult
