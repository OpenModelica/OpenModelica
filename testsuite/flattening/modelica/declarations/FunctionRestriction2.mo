// name: FunctionRestriction2
// keywords:
// status: incorrect
//

function f
  input Real x;
  output Real y;
initial algorithm
  y := x;
end f;

model FunctionRestriction2
  Real x = f(1.0);
end FunctionRestriction2;

// Result:
// Error processing file: FunctionRestriction2.mo
// [flattening/modelica/declarations/FunctionRestriction2.mo:10:3-10:9:writable] Error: Initial algorithm sections are not allowed in function.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
