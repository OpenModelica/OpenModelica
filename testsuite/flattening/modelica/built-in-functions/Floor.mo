// name: Floor
// keywords: floor
// status: correct
//
// Tests the built-in floor function
//

model Floor
  Real r;
equation
  r = floor(4.5);
end Floor;

// Result:
// class Floor
//   Real r;
// equation
//   r = 4.0;
// end Floor;
// endResult
