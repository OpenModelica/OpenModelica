// name:     modelica_1_1_Array9
// keywords: array, construction
// status:   correct
//
//

model Array9
  Real x[2]={1,2};
//  Real y[2,3]={{1,2,3},{4,5,6}};
end Array9;

// Result:
// class Array9
//   Real x[1];
//   Real x[2];
// equation
//   x = {1.0, 2.0};
// end Array9;
// endResult
