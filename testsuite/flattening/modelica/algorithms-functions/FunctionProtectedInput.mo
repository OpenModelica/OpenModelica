// name: FunctionProtectedInput
// status: incorrect

model FunctionProtectedInput

function fn
  protected Real r;
  input Real inR;
  output Real outR;
algorithm
  outR := inR;
end fn;

  Real r, r2;
equation
  r = fn(r2);
end FunctionProtectedInput;

// Result:
// Error processing file: FunctionProtectedInput.mo
// [flattening/modelica/algorithms-functions/FunctionProtectedInput.mo:9:3-9:19:writable] Error: Invalid protected variable outR, function variables that are input/output must be public.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
