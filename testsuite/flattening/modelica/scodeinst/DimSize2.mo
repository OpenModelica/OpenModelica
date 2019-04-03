// name: DimSize2
// keywords:
// status: correct
// cflags: -d=newInst
//

model DimSize2
  Real x[size(x, 2), 3];
end DimSize2;

// Result:
// class DimSize2
//   Real x[1,1];
//   Real x[1,2];
//   Real x[1,3];
//   Real x[2,1];
//   Real x[2,2];
//   Real x[2,3];
//   Real x[3,1];
//   Real x[3,2];
//   Real x[3,3];
// end DimSize2;
// endResult
