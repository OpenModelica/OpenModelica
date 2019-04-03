// name:     test_05.mo
// keywords: <insert keywords here>
// status:   correct
//
// <insert description here>
//

model simple_test
  Real a;
  Real b;
equation
  der(a) = 6*a - 2*a^2 - a*b;
  der(b) = 4*b - a*b - b^2;
end simple_test;

// Result:
// class simple_test
//   Real a;
//   Real b;
// equation
//   der(a) = 6.0 * a - 2.0 * a ^ 2.0 - a * b;
//   der(b) = 4.0 * b - a * b - b ^ 2.0;
// end simple_test;
// endResult
