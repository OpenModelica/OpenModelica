// name: FunctionRestriction1
// keywords:
// status: incorrect
//

function f
  input Real x;
  output Real y;
equation
  y = x;
end f;

model FunctionRestriction1
  Real x = f(1.0);
end FunctionRestriction1;

// Result:
// Error processing file: FunctionRestriction1.mo
// [flattening/modelica/declarations/FunctionRestriction1.mo:10:3-10:8:writable] Error: Equations are not allowed in function.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
