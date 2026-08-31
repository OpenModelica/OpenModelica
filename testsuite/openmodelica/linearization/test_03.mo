// name:     test_03.mo
// keywords: <insert keywords here>
// status:   correct
//
// <insert description here>
//

model simple_test
  Real a(start=2);
  Real b(start=3);
  Real c(start=5);
equation
  a + b + c = der(a);
  a + b*2 + c = 5;
  a + b + c*2 = 7;
end simple_test;

// Result:
// class simple_test
//   Real a(start = 2.0);
//   Real b(start = 3.0);
//   Real c(start = 5.0);
// equation
//   a + (b + c) = der(a);
//   a + (2.0 * b + c) = 5.0;
//   a + (b + 2.0 * c) = 7.0;
// end simple_test;
// endResult
