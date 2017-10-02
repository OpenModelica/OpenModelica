// name: End1
// keywords:
// status: correct
// cflags: -d=newInst
//
//

model End1
  Real x[3];
equation
  x[end] = 1;
end End1;

// Result:
// class End1
//   Real x[1];
//   Real x[2];
//   Real x[3];
// equation
//   x[3] = 1;
// end End1;
// endResult
