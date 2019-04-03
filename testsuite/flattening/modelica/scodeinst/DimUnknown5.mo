// name: DimUnknown5
// keywords:
// status: correct
// cflags: -d=newInst
//
//

model DimUnknown5
  Real x[2, :] = y;
  Real y[:, 3] = x;
end DimUnknown5;

// Result:
// class DimUnknown5
//   Real x[1,1];
//   Real x[1,2];
//   Real x[1,3];
//   Real x[2,1];
//   Real x[2,2];
//   Real x[2,3];
//   Real y[1,1];
//   Real y[1,2];
//   Real y[1,3];
//   Real y[2,1];
//   Real y[2,2];
//   Real y[2,3];
// equation
//   x = y;
//   y = x;
// end DimUnknown5;
// endResult
