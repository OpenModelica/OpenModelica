// name: SlicedCref5
// keywords:
// status: correct
//

model SlicedCref5
  Real x[3, 2];
  Real y[3, 2];
algorithm
  x[1:2] := y[2:3];
  x[1:3] := y[3:-1:1];
end SlicedCref5;

// Result:
// class SlicedCref5
//   Real x[1,1];
//   Real x[1,2];
//   Real x[2,1];
//   Real x[2,2];
//   Real x[3,1];
//   Real x[3,2];
//   Real y[1,1];
//   Real y[1,2];
//   Real y[2,1];
//   Real y[2,2];
//   Real y[3,1];
//   Real y[3,2];
// algorithm
//   x[1:2,:] := y[2:3,:];
//   x[:,:] := y[3:-1:1,:];
// end SlicedCref5;
// endResult
