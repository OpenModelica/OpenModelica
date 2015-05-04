// name:     Array10
// keywords: array
// status:   correct
//
// An array of mixed integer and reals is automatically cast to an
// array of Reals. Fixes bug #37
//

model Array10
  Real x[5] = {1.,2,3.0,4,5.0};
  Real y[:,:] = {{1,2.},{3.,4}};
end Array10;


// Result:
// class Array10
//   Real x[1];
//   Real x[2];
//   Real x[3];
//   Real x[4];
//   Real x[5];
//   Real y[1,1];
//   Real y[1,2];
//   Real y[2,1];
//   Real y[2,2];
// equation
//   x = {1.0, 2.0, 3.0, 4.0, 5.0};
//   y = {{1.0, 2.0}, {3.0, 4.0}};
// end Array10;
// endResult
