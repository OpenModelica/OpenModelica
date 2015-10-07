// name:     BooleanRanges
// keywords: boolean range
// status:   correct
//
// Tests boolean ranges.
//

model BooleanRanges
  Boolean b1[:] = false : true;
  Boolean b2[:] = true : false;
  Boolean b3[:] = false : false;
  Boolean b4[:] = true : true;
end BooleanRanges;

// Result:
// class BooleanRanges
//   Boolean b1[1];
//   Boolean b1[2];
//   Boolean b3[1];
//   Boolean b4[1];
// equation
//   b1 = {false, true};
//   b3 = {false};
//   b4 = {true};
// end BooleanRanges;
// endResult
