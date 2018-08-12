// name: FunctionVariability
// keywords: function variability
// status: incorrect

function f
  constant input Real x;
  output Real y;
algorithm
  y := x;
end f;

model FunctionVariability
  Real a, b = f(a);
end FunctionVariability;

// Result:
// Error processing file: FunctionVariability.mo
// [flattening/modelica/algorithms-functions/FunctionVariability.mo:13:3-13:19:writable] Error: Function argument x=a in call to f has variability continuous which is not a constant expression.
// Error: Error occurred while flattening model FunctionVariability
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
