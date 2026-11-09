// name:     SmallLinsys
// keywords:
// status:   correct
//

model LinSys
  Real x(start=1);
  Real y(start=2);
  Real z(start=3);
equation
   der(x) + z*der(y) + der(z) = 1;
   z*der(y)-x*der(z) = 3;
   der(z)+der(x)-x*der(y) = 1;
end LinSys;

// Result:
// class LinSys
//   Real x(start = 1.0);
//   Real y(start = 2.0);
//   Real z(start = 3.0);
// equation
//   der(x) + z * der(y) + der(z) = 1.0;
//   z * der(y) - x * der(z) = 3.0;
//   der(z) + der(x) - x * der(y) = 1.0;
// end LinSys;
// endResult
