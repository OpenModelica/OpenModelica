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
// [flattening/modelica/algorithms-functions/FunctionProtectedInput.mo:8:3-8:17:writable] Error: Invalid protected variable inR, function variables that are input/output must be public.
// [flattening/modelica/algorithms-functions/FunctionProtectedInput.mo:16:3-16:13:writable] Error: Class fn not found in scope FunctionProtectedInput (looking for a function or record).
// Error: Error occurred while flattening model FunctionProtectedInput
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
