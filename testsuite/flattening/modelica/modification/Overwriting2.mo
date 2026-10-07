// name:     Overwriting2
// keywords: modification,equation
// status:   correct
//
// The modification for `x' does not overwrite the equation.

class Overwriting2
  Real x = 5.0+u;
  Real u;
equation
  x = 2.0;
end Overwriting2;

// Result:
// class Overwriting2
//   Real x = 5.0 + u;
//   Real u;
// equation
//   x = 2.0;
// end Overwriting2;
// [flattening/modelica/modification/Overwriting2.mo:8:3-8:17:writable] Warning: Components are deprecated in class.
// [flattening/modelica/modification/Overwriting2.mo:9:3-9:9:writable] Warning: Components are deprecated in class.
// [flattening/modelica/modification/Overwriting2.mo:11:3-11:10:writable] Warning: Equation sections are deprecated in class.
//
// endResult
