// name:     modelica_1_1_Type9
// keywords: types
// status:   correct
//
// Checks that subscripts are handled in a correct manner int the component clause.
//

class Type9
  Real[3] x[2];
  Real y[2,3];
  Real ok[3];
equation
  x = y;
  ok[1]=3.0;
end Type9;

// Result:
// class Type9
//   Real x[1,1];
//   Real x[1,2];
//   Real x[1,3];
//   Real x[2,1];
//   Real x[2,2];
//   Real x[2,3];
//   Real y[1,1];
//   Real y[1,2];
//   Real y[1,3];
//   Real y[2,1];
//   Real y[2,2];
//   Real y[2,3];
//   Real ok[1];
//   Real ok[2];
//   Real ok[3];
// equation
//   x[1,1] = y[1,1];
//   x[1,2] = y[1,2];
//   x[1,3] = y[1,3];
//   x[2,1] = y[2,1];
//   x[2,2] = y[2,2];
//   x[2,3] = y[2,3];
//   ok[1] = 3.0;
// end Type9;
// endResult
