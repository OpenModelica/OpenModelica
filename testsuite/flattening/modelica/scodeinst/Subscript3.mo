// name: Subscript3
// status: correct
// cflags: -d=newInst
//
//

model Subscript3
  Real x[3, 2] = {{1, 2}, {3, 4}, {5, 6}};
  Real y[2, 1];
equation
  y = x[2:3, 1:1];
end Subscript3;

// Result:
// class Subscript3
//   Real x[1,1];
//   Real x[1,2];
//   Real x[2,1];
//   Real x[2,2];
//   Real x[3,1];
//   Real x[3,2];
//   Real y[1,1];
//   Real y[2,1];
// equation
//   x = {{1.0, 2.0}, {3.0, 4.0}, {5.0, 6.0}};
//   y[1,1] = x[2,1];
//   y[2,1] = x[3,1];
// end Subscript3;
// endResult
