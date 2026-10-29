// name:     BooleanDim
// keywords: boolean dimension
// status:   correct
//
// Tests the use of Boolean as dimension.
//

model BooleanDim
  Real x[Boolean] = {if b then 1.5 else 2.5 for b in Boolean};
end BooleanDim;

// Result:
// class BooleanDim
//   Real x[false];
//   Real x[true];
// equation
//   x = array(if b then 1.5 else 2.5 for b in {false, true});
// end BooleanDim;
// endResult
