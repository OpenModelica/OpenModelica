// name:     Array4
// keywords: array
// status:   correct
//
// This is a test of arrays of arrays.  The type T2 is equivalent or
// similar to Real[2,3].
//

model Array4
  type T1 = Real[3];
  type T2 = T1[2];
  parameter T2 x;
end Array4;

// Result:
// class Array4
//   parameter Real x[1,1];
//   parameter Real x[1,2];
//   parameter Real x[1,3];
//   parameter Real x[2,1];
//   parameter Real x[2,2];
//   parameter Real x[2,3];
// end Array4;
// endResult
