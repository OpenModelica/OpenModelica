// name: Subscript1.mo
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
//   Real x[1] = 1;
//   Real x[2] = 2;
//   Real x[3] = 3;
//   Real y = x[2];
// end Subscript1;
// endResult
