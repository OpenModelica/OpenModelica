// name:     Shadow1
// keywords: modification,shadow
// status:   correct
//
// Modifications override declarations but not equations.

class A
  Real y=3.0;
  Real x;
equation
  x = 1;
end A;

model Shadow1
  Real z;
  A a(x = z, y=2.0);
end Shadow1;


// Result:
// class Shadow1
//   Real z;
//   Real a.y = 2.0;
//   Real a.x = z;
// equation
//   a.x = 1.0;
// end Shadow1;
// endResult
