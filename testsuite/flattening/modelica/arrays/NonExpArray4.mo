// name:     Non-expanded Array 4
// keywords: array
// status:   correct
// cflags:   +a
//
// This is a simple test of non-expanded array handling.
// It tests using expressions of non-constant dimension as attribute values.
//

model Array4
  parameter Integer p;
  Real y[p](start = fill(0.0,p));
end Array4;

// Result:
// class Array4
//   parameter Integer p;
//   Real y[1:p](start = fill(0.0, p));
// end Array4;
// endResult
