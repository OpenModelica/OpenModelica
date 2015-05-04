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
// [flattening/modelica/equations/EqualityEquations.mo:29:3-29:33:writable] Error: Tuple assignment only allowed for tuple of component references in lhs (in (x + 1, 3.0, z / y) = f(1.0, 2.0);).
// Error: Error occurred while flattening model EqualityEquations
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
