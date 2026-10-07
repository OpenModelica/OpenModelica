// name:     Constant1
// keywords: declaration
// status:   correct
//
// Basic constant definitions.
//

class Constant1
  constant Real PI = 3.14159265358979;
  constant Integer N = 17;
  Real x;
equation
  x = 2.0 * PI;
end Constant1;

// Result:
// class Constant1
//   constant Real PI = 3.14159265358979;
//   constant Integer N = 17;
//   Real x;
// equation
//   x = 6.28318530717958;
// end Constant1;
// [flattening/modelica/declarations/Constant1.mo:9:3-9:38:writable] Warning: Components are deprecated in class.
// [flattening/modelica/declarations/Constant1.mo:10:3-10:26:writable] Warning: Components are deprecated in class.
// [flattening/modelica/declarations/Constant1.mo:11:3-11:9:writable] Warning: Components are deprecated in class.
// [flattening/modelica/declarations/Constant1.mo:13:3-13:15:writable] Warning: Equation sections are deprecated in class.
//
// endResult
