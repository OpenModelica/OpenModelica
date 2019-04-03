// name: dim7.mo
// keywords:
// status: correct
// cflags:   -d=newInst
//


model A
  Real x[size(x, 2), size(x, 3), size(x, 4), 2];
  Real y[size(y, 2), 2];
end A;

// Result:
// class A
//   Real x[1,1,1,1];
//   Real x[1,1,1,2];
//   Real x[1,1,2,1];
//   Real x[1,1,2,2];
//   Real x[1,2,1,1];
//   Real x[1,2,1,2];
//   Real x[1,2,2,1];
//   Real x[1,2,2,2];
//   Real x[2,1,1,1];
//   Real x[2,1,1,2];
//   Real x[2,1,2,1];
//   Real x[2,1,2,2];
//   Real x[2,2,1,1];
//   Real x[2,2,1,2];
//   Real x[2,2,2,1];
//   Real x[2,2,2,2];
//   Real y[1,1];
//   Real y[1,2];
//   Real y[2,1];
//   Real y[2,2];
// end A;
// endResult
