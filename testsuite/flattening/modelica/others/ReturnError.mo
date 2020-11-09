// name: ReturnError
// status: incorrect
// cflags: -d=-newInst

model ReturnError
algorithm
  return;
end ReturnError;

// Result:
// Error processing file: ReturnError.mo
// [flattening/modelica/others/ReturnError.mo:7:3-7:9:writable] Error: 'return' may not be used outside function.
// Error: Error occurred while flattening model ReturnError
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
