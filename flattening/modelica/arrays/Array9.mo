// name:      Array9
// keywords:  array
// status:    correct
//
// End keyword in array subscript
//

class Array9
  Integer a[:] = 3:5;
  parameter Integer b[:] = {3,2};
  Real c[b[end]];
algorithm
  a[end-b[end]] := 1;
end Array9;

// Result:
// class Array9
//   Integer a[1];
//   Integer a[2];
//   Integer a[3];
//   parameter Integer b[1] = 3;
//   parameter Integer b[2] = 2;
//   Real c[1];
//   Real c[2];
// equation
//   a = {3, 4, 5};
// algorithm
//   a[1] := 1;
// end Array9;
// endResult
