// name: DimSize3
// keywords:
// status: correct
// cflags: -d=newInst
//

model DimSize3
  Real x[size(x, 2), 3];
end DimSize3;

// Result:
// class DimSize3
//   Real x[1,1];
//   Real x[1,2];
//   Real x[1,3];
//   Real x[2,1];
//   Real x[2,2];
//   Real x[2,3];
//   Real x[3,1];
//   Real x[3,2];
//   Real x[3,3];
// end DimSize3;
// endResult
