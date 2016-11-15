// name: eq8.mo
// keywords:
// status: correct
// cflags:   -d=newInst
//

model A
  Real x[3], y[3];
equation
  x = y;
end A;

model B
  A a(x = {1, 2, 3});
end B;

// Result:
// class B
//   Real a.x[1] = 1.0;
//   Real a.x[2] = 2.0;
//   Real a.x[3] = 3.0;
//   Real a.y[1];
//   Real a.y[2];
//   Real a.y[3];
// equation
//   a.x[1] = a.y[1];
//   a.x[2] = a.y[2];
//   a.x[3] = a.y[3];
// end B;
// endResult
