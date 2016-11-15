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
//   Real a.x[1] = 1.0;
//   Real a.x[2] = 2.0;
//   Real a.x[3] = 3.0;
//   Real a.y[1] = a.x[1];
//   Real a.y[2] = a.x[2];
//   Real a.y[3] = a.x[3];
// end B;
// endResult
