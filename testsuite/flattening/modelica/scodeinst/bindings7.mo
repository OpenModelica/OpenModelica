// name: bindings7.mo
// keywords:
// status: correct
// cflags:   -d=newInst
//

model A
  Real x[3];
  Real y[3] = x;
end A;

model B
  A a(x = {1, 2, 3});
end B;

// Result:
// class B
//   Real a.x[1];
//   Real a.x[2];
//   Real a.x[3];
//   Real a.y[1];
//   Real a.y[2];
//   Real a.y[3];
// equation
//   a.x = {1.0, 2.0, 3.0};
//   a.y = a.x;
// end B;
// endResult
