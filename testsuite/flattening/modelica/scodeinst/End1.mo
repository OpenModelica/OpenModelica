// name: End1
// keywords:
// status: correct
// cflags: -d=newInst
//
//

model End1
  type E = enumeration(one, two, three);
  Real x[3];
  Real y[E];
  Real z[Boolean];
equation
  x[end] = 1;
  y[end] = 1;
  z[end] = 1;
end End1;

// Result:
// class End1
//   Real x[1];
//   Real x[2];
//   Real x[3];
//   Real y[E.one];
//   Real y[E.two];
//   Real y[E.three];
//   Real z[false];
//   Real z[true];
// equation
//   x[3] = 1.0;
//   y[E.three] = 1.0;
//   z[true] = 1.0;
// end End1;
// endResult
