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
// [flattening/modelica/types/Type11.mo:10:3-10:45:writable] Warning: Components are deprecated in class.
// [flattening/modelica/types/Type11.mo:11:3-11:44:writable] Warning: Components are deprecated in class.
// [flattening/modelica/types/Type11.mo:13:3-13:13:writable] Warning: Components are deprecated in class.
// [flattening/modelica/types/Type11.mo:15:3-15:12:writable] Warning: Equation sections are deprecated in class.
//
// endResult
