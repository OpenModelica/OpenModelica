// name:     Function4
// keywords: function
// status:   incorrect
//
// This tests for illegal parts of a function definition.
//

function f
  input Real x;
  output Real y;
  constant Integer n = 5;
algorithm
  y := x;
end f;

model Function4
  Real x, y;
equation
  x = f(y);
end Function4;
