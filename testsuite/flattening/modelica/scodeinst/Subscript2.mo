// name: Subscript2
// status: correct
// cflags: -d=newInst
//
//

model Subscript2
  Real x[3] = {1, 2, 3};
  Real y[2] = x[2:3];
end Subscript2;

// Result:
// class Subscript2
//   Real x[1];
//   Real x[2];
//   Real x[3];
//   Real y[1];
//   Real y[2];
// equation
//   x = {1.0, 2.0, 3.0};
//   y = x[2:3];
// end Subscript2;
// endResult
