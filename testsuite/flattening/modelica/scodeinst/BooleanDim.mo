// name: BooleanDim.mo
// keywords:
// status: correct
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
