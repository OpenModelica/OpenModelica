// name: FunctionWithEquation
// status: incorrect

model FunctionWithEquation

function fn
  input Real inR;
  output Real outR;
equation
  assert(true, "This really should succeed ;)");
end fn;

  Real r, r2;
equation
  r = fn(r2);
end FunctionWithEquation;

// Result:
// Error processing file: FunctionWithEquation.mo
// [flattening/modelica/algorithms-functions/FunctionWithEquation.mo:10:3-10:48:writable] Error: Equations are not allowed in function.
// Error: Error occurred while flattening model FunctionWithEquation
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
