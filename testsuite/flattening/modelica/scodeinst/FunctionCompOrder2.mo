// name: FunctionCompOrder2
// keywords:
// status: incorrect
//

function f
  input Real x;
  output Real y;
protected
  Real x1 = x2;
  Real x2 = x1;
algorithm
  y := x1;
end f;

model FunctionCompOrder2
  Real x = f(time);
end FunctionCompOrder2;

// Result:
// Error processing file: FunctionCompOrder2.mo
// [flattening/modelica/scodeinst/FunctionCompOrder2.mo:6:1-14:6:writable] Error: Cyclically dependent function components found: {x2, x1}
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
