// name: DimUnknown7
// keywords:
// status: correct
// cflags: -d=newInst
//
//

model DimUnknown7
  Real x[:](start = {1, 2, 3});
end DimUnknown7;

// Result:
// class DimUnknown7
//   Real x[1](start = 1.0);
//   Real x[2](start = 2.0);
//   Real x[3](start = 3.0);
// end DimUnknown7;
// endResult
