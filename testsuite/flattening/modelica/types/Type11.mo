// name:     Type11
// keywords: types
// status:   correct
//
// Checks that subscripts are handled in a correct manner int the component clause.
//
//

class Type11
  Real[3] x[2]=[[11.,12.,13.];[21.,22.,23.]];
  Real y[2,3]=[[11.,12.,13.];[21.,22.,23.]];

  Real ok[3];
equation
  ok[1]=3.0;
end Type11;

// Result:
// class Type11
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
//   x = {{11.0, 12.0, 13.0}, {21.0, 22.0, 23.0}};
//   y = {{11.0, 12.0, 13.0}, {21.0, 22.0, 23.0}};
//   ok[1] = 3.0;
// end Type11;
// endResult
