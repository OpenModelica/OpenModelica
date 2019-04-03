// name:     Function2
// keywords: function
// status:   correct
//
// This tests for illegal parts of a function definition.
// This test should really fail, but since the MSL uses public non-formal
// parameters we can only print a warning.
//

function f
  input Real x;
  output Real r;
  Real toomuch;
algorithm
  r := 2.0 * x;
end f;

model Function2
  Real x, z;
equation
  x = f(z);
end Function2;

// Result:
// function f
//   input Real x;
//   output Real r;
//   Real toomuch;
// algorithm
//   r := 2.0 * x;
// end f;
//
// class Function2
//   Real x;
//   Real z;
// equation
//   x = f(z);
// end Function2;
// [flattening/modelica/algorithms-functions/Function2.mo:13:3-13:15:writable] Warning: Invalid public variable toomuch, function variables that are not input/output must be protected.
//
// endResult
