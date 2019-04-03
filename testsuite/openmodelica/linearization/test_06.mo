// name:     test_06.mo
// keywords: <insert keywords here>
// status:   correct
//
// <insert description here>
//

model simple_test
  parameter Real param = 5.0;
  Real u;
  Real u1;
  Real u2;
  Real i1, i2;
algorithm
  u := sin(time);
  u := sin(param*time)+u;
equation
  param*der(i1) = u1;
  der(i2) = u2*i2*(u2+1);
  u=u1+u2;
  i1=i2;
end simple_test;

// Result:
// class simple_test
//   parameter Real param = 5.0;
//   Real u;
//   Real u1;
//   Real u2;
//   Real i1;
//   Real i2;
// equation
//   param * der(i1) = u1;
//   der(i2) = u2 * (i2 * (1.0 + u2));
//   u = u1 + u2;
//   i1 = i2;
// algorithm
//   u := sin(time);
//   u := sin(param * time) + u;
// end simple_test;
// endResult
