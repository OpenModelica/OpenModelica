// name: End5
// keywords:
// status: correct
// cflags: -d=newInst
//
//

model End5
  Real x[4, 3];
  Integer y[2];
equation
  x[y[end], end] = time;
end End5;

// Result:
// class End5
//   Real x[1,1];
//   Real x[1,2];
//   Real x[1,3];
//   Real x[2,1];
//   Real x[2,2];
//   Real x[2,3];
//   Real x[3,1];
//   Real x[3,2];
//   Real x[3,3];
//   Real x[4,1];
//   Real x[4,2];
//   Real x[4,3];
//   Integer y[1];
//   Integer y[2];
// equation
//   x[y[2],3] = time;
// end End5;
// endResult
