// name: ReturnError
// status: incorrect

model ReturnError
algorithm
  return;
end ReturnError;

// Result:
// Error processing file: ReturnError.mo
// [flattening/modelica/others/ReturnError.mo:6:3-6:9:writable] Error: 'return' may not be used outside function.
// Error: Error occurred while flattening model ReturnError
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
