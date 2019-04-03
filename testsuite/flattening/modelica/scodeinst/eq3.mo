// name: eq3.mo
// keywords:
// status: correct
// cflags:   -d=newInst
//

model A
  Real x;
  Real y[3];
equation
  y = {x, x, x};
end A;

model B
  A a[3](x = {1, 2, 3});
end B;

// Result:
// class B
//   Real a[1].x = 1.0;
//   Real a[1].y[1];
//   Real a[1].y[2];
//   Real a[1].y[3];
//   Real a[2].x = 2.0;
//   Real a[2].y[1];
//   Real a[2].y[2];
//   Real a[2].y[3];
//   Real a[3].x = 3.0;
//   Real a[3].y[1];
//   Real a[3].y[2];
//   Real a[3].y[3];
// equation
//   a[1].y[1] = a[1].x;
//   a[1].y[2] = a[1].x;
//   a[1].y[3] = a[1].x;
//   a[2].y[1] = a[2].x;
//   a[2].y[2] = a[2].x;
//   a[2].y[3] = a[2].x;
//   a[3].y[1] = a[3].x;
//   a[3].y[2] = a[3].x;
//   a[3].y[3] = a[3].x;
// end B;
// endResult
