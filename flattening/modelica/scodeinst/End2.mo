
// name: End2
// keywords:
// status: correct
// cflags: -d=newInst
//
//

model End2
  Real x[3, 4, 1];
equation
  x[end, end, end] = 1;
end End2;

// Result:
// class End2
//   Real x[1,1,1];
//   Real x[1,2,1];
//   Real x[1,3,1];
//   Real x[1,4,1];
//   Real x[2,1,1];
//   Real x[2,2,1];
//   Real x[2,3,1];
//   Real x[2,4,1];
//   Real x[3,1,1];
//   Real x[3,2,1];
//   Real x[3,3,1];
//   Real x[3,4,1];
// equation
//   x[3,4,1] = 1.0;
// end End2;
// endResult
