// name:     EqualityEquations
// keywords: equation
// status:   incorrect
//
// Illegal equations
// Drmodelica: 8.2 Simple Equality Equations (p. 240)
//
function f
  input Real a;
  input Real b;
  output Real c;
  output Real d;
  output Real e;
algorithm
  c := a + b;
  d := a - b;
  e := a * b;
end f;

class EqualityEquations
  Real x;
  Real y;
  Real z;
  Real u;
  Real v = 2;
equation
  u = v;                    // Equality equations between two expressions
  (x, y, z)      = f(1.0, 2.0);        // Correct!
  (x+1, 3.0, z/y)  = f(1.0, 2.0);        // Illegal! Not a list of variables on the left hand side
end EqualityEquations;

// Result:
// Error processing file: EqualityEquations.mo
// [flattening/modelica/equations/EqualityEquations.mo:21:3-21:9:writable] Warning: Components are deprecated in class.
// [flattening/modelica/equations/EqualityEquations.mo:22:3-22:9:writable] Warning: Components are deprecated in class.
// [flattening/modelica/equations/EqualityEquations.mo:23:3-23:9:writable] Warning: Components are deprecated in class.
// [flattening/modelica/equations/EqualityEquations.mo:24:3-24:9:writable] Warning: Components are deprecated in class.
// [flattening/modelica/equations/EqualityEquations.mo:25:3-25:13:writable] Warning: Components are deprecated in class.
// [flattening/modelica/equations/EqualityEquations.mo:27:3-27:8:writable] Warning: Equation sections are deprecated in class.
// [flattening/modelica/equations/EqualityEquations.mo:29:3-29:33:writable] Error: Tuple assignment only allowed for tuple of component references in lhs (in (x + 1.0, 3.0, z / y)).
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
