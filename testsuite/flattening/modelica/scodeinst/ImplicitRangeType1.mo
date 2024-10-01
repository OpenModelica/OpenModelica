// name: ImplicitRangeType1
// keywords:
// status: correct
//
//

model ImplicitRangeType1
  Real x[Boolean];
equation
  for i loop
    x[i] = 1;
  end for;
end ImplicitRangeType1;

// Result:
// class ImplicitRangeType1
//   Real x[false];
//   Real x[true];
// equation
//   x[false] = 1.0;
//   x[true] = 1.0;
// end ImplicitRangeType1;
// endResult
