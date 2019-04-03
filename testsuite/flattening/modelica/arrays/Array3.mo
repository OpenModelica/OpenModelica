// name:     Array3
// keywords: array
// status:   correct
//
// This is a simple test of basic matrix handling.
//

model Array3
  Integer x[2,3] = [ 1,2,3 ; 4,5,6 ] ;
end Array3;


// Result:
// class Array3
//   Integer x[1,1];
//   Integer x[1,2];
//   Integer x[1,3];
//   Integer x[2,1];
//   Integer x[2,2];
//   Integer x[2,3];
// equation
//   x = {{1, 2, 3}, {4, 5, 6}};
// end Array3;
// endResult
