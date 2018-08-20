// name: Subscript6
// status: correct
// cflags: -d=newInst
//
// 

model Subscript6
  Real x[2, 2, 2];
  Real y[2];
  Integer i;
equation
  y = x[i, 2, :] - x[i, 1, :];
end Subscript6;
  
// Result:
// class Subscript6
//   Real x[1,1,1];
//   Real x[1,1,2];
//   Real x[1,2,1];
//   Real x[1,2,2];
//   Real x[2,1,1];
//   Real x[2,1,2];
//   Real x[2,2,1];
//   Real x[2,2,2];
//   Real y[1];
//   Real y[2];
//   Integer i;
// equation
//   y[1] = x[i,2,1] - x[i,1,1];
//   y[2] = x[i,2,2] - x[i,1,2];
// end Subscript6;
// endResult
