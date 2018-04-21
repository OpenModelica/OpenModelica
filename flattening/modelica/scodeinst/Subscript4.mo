// name: Subscript4
// status: correct
// cflags: -d=newInst
//
//

model Subscript4
  type Real3 = Real[3];
  Real3 x = {1, 2, 3};
  Real y = x[2];
end Subscript4;

// Result:
// class Subscript4
//   Real x[1];
//   Real x[2];
//   Real x[3];
//   Real y = x[2];
// equation
//   x = {1.0, 2.0, 3.0};
// end Subscript4;
// endResult
