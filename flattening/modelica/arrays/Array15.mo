// name:     Array15
// keywords: arrays, empty arrays
// status:   correct
//
// Creating empty arrays using fill
//

model Array15
  constant Real a[:,:]=fill(0.0,0,2);
  constant Real b[:,:]=fill(0.0,2,0);
  parameter Integer n1 = size(a,2);
  parameter Integer m1 = size(a,1);
  parameter Integer n2 = size(b,1);
  parameter Integer m2 = size(b,2);
end Array15;
// Result:
// class Array15
//   parameter Integer n1 = 2;
//   parameter Integer m1 = 0;
//   parameter Integer n2 = 2;
//   parameter Integer m2 = 0;
// end Array15;
// endResult
