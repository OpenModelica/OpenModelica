// name: eq1.mo
// keywords:
// status: correct
//

model A
  Real x;
  Real y;
equation
  x = 2;
  y = 3;
end A;

// Result:
// class A
//   Real x;
//   Real y;
// equation
//   x = 2.0;
//   y = 3.0;
// end A;
// endResult
