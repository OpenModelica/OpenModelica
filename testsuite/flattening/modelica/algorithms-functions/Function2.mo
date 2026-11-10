// name:     Function2
// keywords: function
// status:   incorrect
//
// This tests for illegal parts of a function definition.
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
// Error processing file: Function2.mo
// [flattening/modelica/algorithms-functions/Function2.mo:11:3-11:15:writable] Error: Invalid public variable toomuch, function variables that are not input/output must be protected.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
