// name:     Function8
// keywords: function
// status:   incorrect
//
// This tests basic function functionality
//

function f
  input Real x;
  output Real r;
algorithm
  r := 2.0 * x;
end f;

model Function8
  Real x;
  String z;
equation
  x = f(z);
end Function8;
// Result:
// Error processing file: Function8.mo
// [flattening/modelica/algorithms-functions/Function8.mo:19:3-19:11:writable] Error: Type mismatch for positional argument 1 in f(x=z). The argument has type:
//   String
// expected type:
//   Real
// Error: Error occurred while flattening model Function8
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
