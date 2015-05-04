// name: ErrorUnknownDimension
// status: incorrect

model ErrorUnknownDimension
  Real r[:];
end ErrorUnknownDimension;
// Result:
// Error processing file: ErrorUnknownDimension.mo
// [ErrorUnknownDimension.mo:5:3-5:12:writable] Error: Failed to deduce dimensions of r due to missing binding equation.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
