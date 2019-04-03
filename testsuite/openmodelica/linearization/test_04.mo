// name:     test_04.mo
// keywords: <insert keywords here>
// status:   correct
//
// <insert description here>
//

model simple_test
 Real x1(start=1);
 Real x2(start=2);
 parameter Real a=6,b=2,c=4;
 input Real u = sin(0);
 output Real y;
equation
 der(x1) = x1*(a-b*x1-x2);
 der(x2) = x2*(c-x1-x2);
 y = x1 * u + x2 * u;
end simple_test;

// Result:
// class simple_test
//   Real x1(start = 1.0);
//   Real x2(start = 2.0);
//   parameter Real a = 6.0;
//   parameter Real b = 2.0;
//   parameter Real c = 4.0;
//   input Real u = 0.0;
//   output Real y;
// equation
//   der(x1) = x1 * (a - b * x1 - x2);
//   der(x2) = x2 * (c - x1 - x2);
//   y = x1 * u + x2 * u;
// end simple_test;
// endResult
