// name:     BooleanArrayEq
// keywords: array Boolean equation
// status:   correct
//
// Tests array equations with components indexed by Boolean.
//

model BooleanArrayEq
  Boolean arr[Boolean];
equation
  arr = {true, true};
end BooleanArrayEq;

// Result:
// class BooleanArrayEq
//   Boolean arr[false];
//   Boolean arr[true];
// equation
//   arr[false] = true;
//   arr[true] = true;
// end BooleanArrayEq;
// endResult
