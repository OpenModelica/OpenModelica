// name: DimSize1
// keywords:
// status: correct
// cflags: -d=newInst
//

model DimSize1
  Real x[3];
  Real y[size(x, 1)];
end DimSize1;

// Result:
// class DimSize1
//   Real x[1];
//   Real x[2];
//   Real x[3];
//   Real y[1];
//   Real y[2];
//   Real y[3];
// end DimSize1;
// endResult
