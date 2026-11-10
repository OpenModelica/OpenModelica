// name:     Array2
// keywords: array
// status:   correct
//
// Multidimensional arrays
//

model Array2
  parameter Integer x[2,3](each fixed = false);
end Array2;

// Result:
// class Array2
//   parameter Integer x[1,1](fixed = false);
//   parameter Integer x[1,2](fixed = false);
//   parameter Integer x[1,3](fixed = false);
//   parameter Integer x[2,1](fixed = false);
//   parameter Integer x[2,2](fixed = false);
//   parameter Integer x[2,3](fixed = false);
// end Array2;
// endResult
