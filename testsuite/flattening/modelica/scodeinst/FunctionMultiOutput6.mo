// name:     FunctionMultiOutput6
// keywords:
// status:   incorrect
//

function f
  input Real u;
  output Real y1 = u;
  output Integer y2 = 2;
end f;

model FunctionMultiOutput6
  Real u;
  Integer x1 = 1;
  Real x2;
equation
  (x1, x2) = f(u);
end FunctionMultiOutput6;

//model FunctionMultiOutput4
//  Real x;
//equation
//  x = f(time) + 1;
//end FunctionMultiOutput4;

// Result:
// Error processing file: FunctionMultiOutput6.mo
// [flattening/modelica/scodeinst/FunctionMultiOutput6.mo:17:3-17:18:writable] Error: Type mismatch in equation (x1, x2) = f(u) of type (Integer, Real) = (Real, Integer).
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
