// name:     Array2
// keywords: array
// status:   correct
//
// Multidimensional arrays
//

model Array2
  parameter Integer x[2,3];
end Array2;

// Result:
// class Array2
//   parameter Integer x[1,1];
//   parameter Integer x[1,2];
//   parameter Integer x[1,3];
//   parameter Integer x[2,1];
//   parameter Integer x[2,2];
//   parameter Integer x[2,3];
// end Array2;
// endResult
