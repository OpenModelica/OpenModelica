// name: FunctionRestriction4
// keywords:
// status: incorrect
//

function f
  input Real x;
  output Real y;
protected
  input Real z;
algorithm
  y := x * z;
end f;

model FunctionRestriction4
  Real x = f(1.0);
end FunctionRestriction4;

// Result:
// Error processing file: FunctionRestriction4.mo
// [flattening/modelica/declarations/FunctionRestriction4.mo:10:3-10:15:writable] Error: Invalid protected variable z, function variables that are input/output must be public.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
