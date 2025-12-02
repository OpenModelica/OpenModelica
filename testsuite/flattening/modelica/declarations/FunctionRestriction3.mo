// name: FunctionRestriction3
// keywords:
// status: incorrect
//

function f
  input Real x;
  output Real y;
  Real z;
algorithm
  y := x * z;
end f;

model FunctionRestriction3
  Real x = f(1.0);
end FunctionRestriction3;

// Result:
// Error processing file: FunctionRestriction3.mo
// [flattening/modelica/declarations/FunctionRestriction3.mo:9:3-9:9:writable] Error: Invalid public variable z, function variables that are not input/output must be protected.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
