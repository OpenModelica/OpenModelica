// name: dim17.mo
// keywords:
// status: correct
// cflags:   -d=newInst
//
//

model A
  Real x[2, :] = y;
  Real y[:, 3] = x;
end A;

// Result:
// class A
//   Real x[1,1];
//   Real x[1,2];
//   Real x[1,3];
//   Real x[2,1];
//   Real x[2,2];
//   Real x[2,3];
//   Real y[1,1];
//   Real y[1,2];
//   Real y[1,3];
//   Real y[2,1];
//   Real y[2,2];
//   Real y[2,3];
// equation
//   x = {{y[1,1], y[1,2], y[1,3]}, {y[2,1], y[2,2], y[2,3]}};
//   y = {{x[1,1], x[1,2], x[1,3]}, {x[2,1], x[2,2], x[2,3]}};
// end A;
// endResult
