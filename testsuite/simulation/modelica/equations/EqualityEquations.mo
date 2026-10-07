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

// class EqualityEquations
// Real x;
// Real y;
// Real z;
// Real u;
// Real v;
// equation
//   v = 2.0;
//   u = v;
//   (x,y,z) = (3.0,-1.0,2.0);
//   (1.0 + x,3.0,z * 1.0 / y) = (3.0,-1.0,2.0);
// end EqualityEquations;
