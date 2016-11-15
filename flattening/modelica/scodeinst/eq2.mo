// name: eq2.mo
// keywords:
// status: correct
// cflags:   -d=newInst
//

model A
  Real x;
  Real y[3];
equation
  x = 4;
  y = {1, 2, 3};
end A;

model B
  A a[3];
end B;

// Result:
// class B
//   Real a[1].x;
//   Real a[1].y[1];
//   Real a[1].y[2];
//   Real a[1].y[3];
//   Real a[2].x;
//   Real a[2].y[1];
//   Real a[2].y[2];
//   Real a[2].y[3];
//   Real a[3].x;
//   Real a[3].y[1];
//   Real a[3].y[2];
//   Real a[3].y[3];
// equation
//   a[1].x = 4.0;
//   a[1].y[1] = 1.0;
//   a[1].y[2] = 2.0;
//   a[1].y[3] = 3.0;
//   a[2].x = 4.0;
//   a[2].y[1] = 1.0;
//   a[2].y[2] = 2.0;
//   a[2].y[3] = 3.0;
//   a[3].x = 4.0;
//   a[3].y[1] = 1.0;
//   a[3].y[2] = 2.0;
//   a[3].y[3] = 3.0;
// end B;
// endResult
