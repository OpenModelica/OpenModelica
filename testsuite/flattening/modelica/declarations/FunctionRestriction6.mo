// name: FunctionRestriction6
// keywords:
// status: incorrect
//

function f
  input Real x;
  output Real y;
protected
  outer Real z;
algorithm
  y := x * z;
end f;

model FunctionRestriction6
  Real x = f(1.0);
end FunctionRestriction6;

// Result:
// Error processing file: FunctionRestriction6.mo
// [flattening/modelica/declarations/FunctionRestriction6.mo:10:3-10:15:writable] Error: Invalid prefix outer on formal parameter z.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
