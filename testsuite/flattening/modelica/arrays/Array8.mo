// name:     Array8
// keywords: array,declaration
// status:   correct
//
// This is a test of full slices [:]
//

model Array8
  Real x[2], y[2];
equation
  x[:] = y;
end Array8;

// Result:
// class Array8
//   Real x[1];
//   Real x[2];
//   Real y[1];
//   Real y[2];
// equation
//   x[1] = y[1];
//   x[2] = y[2];
// end Array8;
// endResult
