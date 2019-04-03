// name: End4
// keywords:
// status: correct
// cflags: -d=newInst
//
//

model End4
  Real x[3];
equation
  x[1:end] = {1, 2, 3};
end End4;

// Result:
// class End4
//   Real x[1];
//   Real x[2];
//   Real x[3];
// equation
//   x[1] = 1.0;
//   x[2] = 2.0;
//   x[3] = 3.0;
// end End4;
// endResult
