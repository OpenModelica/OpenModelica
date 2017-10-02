// name: Subscript1
// status: correct
// cflags: -d=newInst
//
//

model Subscript1
  Real x[3] = {1, 2, 3};
  Real y = x[2];
end Subscript1;

// Result:
// class Subscript1
//   Real x[1];
//   Real x[2];
//   Real x[3];
//   Real y = x[2];
// equation
//   x = {1.0, 2.0, 3.0};
// end Subscript1;
// endResult
