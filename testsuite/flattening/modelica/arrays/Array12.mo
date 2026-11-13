// name:     Array12
// keywords: arrays, type conversion
// status:   correct
//
// Type conversion from Integer to Real in arrays.
//

model Array12
  parameter Real a[2,2]={{2,1},{1.2,2.3}};
  parameter Real b[3]={1,2.4,5};
  parameter Real c[2,2]=[1,3.0;4,5.2];
end Array12;
// Result:
// class Array12
//   parameter Real a[1,1] = 2.0;
//   parameter Real a[1,2] = 1.0;
//   parameter Real a[2,1] = 1.2;
//   parameter Real a[2,2] = 2.3;
//   parameter Real b[1] = 1.0;
//   parameter Real b[2] = 2.4;
//   parameter Real b[3] = 5.0;
//   parameter Real c[1,1] = 1.0;
//   parameter Real c[1,2] = 3.0;
//   parameter Real c[2,1] = 4.0;
//   parameter Real c[2,2] = 5.2;
// end Array12;
// endResult
