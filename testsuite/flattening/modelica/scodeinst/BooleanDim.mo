// name: BooleanDim.mo
// keywords:
// status: correct
// cflags: -d=newInst
//

model BooleanDim
  Real x[Boolean];
end BooleanDim;

// Result:
// class BooleanDim
//   Real x[false];
//   Real x[true];
// end BooleanDim;
// endResult
