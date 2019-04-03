// name: DimUnknown1
// keywords:
// status: correct
// cflags: -d=newInst
//


model DimUnknown1
  Real x[:, :] = {{1, 2, 3}, {1, 2, 3}};
end DimUnknown1;

// Result:
// class DimUnknown1
//   Real x[1,1];
//   Real x[1,2];
//   Real x[1,3];
//   Real x[2,1];
//   Real x[2,2];
//   Real x[2,3];
// equation
//   x = {{1.0, 2.0, 3.0}, {1.0, 2.0, 3.0}};
// end DimUnknown1;
// endResult
