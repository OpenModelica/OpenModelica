// name:     SubScript2
// keywords: SubScript simplifications
// status:   correct
//
// Check that subscripts are simplified correctly.
//

model Subscript2
  Real x[3];
  Real y[3,2];
  Real y2[2,3];
  Real s,t;

equation
 s = x[:]*y[:,1];
 t = x*y2[2,:];
end Subscript2;


// Result:
// class Subscript2
//   Real x[1];
//   Real x[2];
//   Real x[3];
//   Real y[1,1];
//   Real y[1,2];
//   Real y[2,1];
//   Real y[2,2];
//   Real y[3,1];
//   Real y[3,2];
//   Real y2[1,1];
//   Real y2[1,2];
//   Real y2[1,3];
//   Real y2[2,1];
//   Real y2[2,2];
//   Real y2[2,3];
//   Real s;
//   Real t;
// equation
//   s = x[1] * y[1,1] + x[2] * y[2,1] + x[3] * y[3,1];
//   t = x[1] * y2[2,1] + x[2] * y2[2,2] + x[3] * y2[2,3];
// end Subscript2;
// endResult
