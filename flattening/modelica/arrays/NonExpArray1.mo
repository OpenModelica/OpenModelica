// name:     Non-expanded Array1
// keywords: array
// status:   correct
// cflags:   +a
//
// This is a simple test of non-expanded array handling.
//

model Array1
  parameter Integer p;
  Real x[5] = {1,2,3,4,5};
  Real y[p];
end Array1;

// Result:
// class Array1
//   parameter Integer p;
//   Real x[1:5];
//   Real y[1:p];
// equation
//   x = {1.0, 2.0, 3.0, 4.0, 5.0};
// end Array1;
// endResult
