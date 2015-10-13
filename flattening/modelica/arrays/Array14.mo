// name:     Array14
// keywords: arrays, empty arrays
// status:   correct
//
// Creating empty arrays using fill
//

model Array14
  Real a[:,:]=fill(0.0,0,2);
  Real b[:,:]=fill(0.0,2,0);
  parameter Integer n1 = size(a,2);
  parameter Integer m1 = size(a,1);
  parameter Integer n2 = size(b,1);
  parameter Integer m2 = size(b,2);
end Array14;
// Result:
// class Array14
//   parameter Integer n1 = 2;
//   parameter Integer m1 = 0;
//   parameter Integer n2 = 2;
//   parameter Integer m2 = 0;
// equation
//   b = {{}, {}};
// end Array14;
// endResult
