// name:     modelica_1_1_Function10
// keywords: function
// status:   correct
//
// Checks that subscripts are handled in a correct manner int the component clause.
//
//

function f
  input Real a;
  input Real b;
  output Real r1;
  output Real r2;
  output Real r3;
algorithm
  r1:=a;
  r2:=b;
  r3:=a+b;
end f;


class Function10
  Real x;
  Real y;
  Real z;
equation
  (x,y,z) = f(1,2);
end Function10;

// Result:
// class Function10
//   Real x;
//   Real y;
//   Real z;
// equation
//   x = 1.0;
//   y = 2.0;
//   z = 3.0;
// end Function10;
// [flattening/modelica/algorithms-functions/modelica_1_1_Function10.mo:23:3-23:9:writable] Warning: Components are deprecated in class.
// [flattening/modelica/algorithms-functions/modelica_1_1_Function10.mo:24:3-24:9:writable] Warning: Components are deprecated in class.
// [flattening/modelica/algorithms-functions/modelica_1_1_Function10.mo:25:3-25:9:writable] Warning: Components are deprecated in class.
// [flattening/modelica/algorithms-functions/modelica_1_1_Function10.mo:27:3-27:19:writable] Warning: Equation sections are deprecated in class.
//
// endResult
