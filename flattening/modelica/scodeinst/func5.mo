// name: func5.mo
// keywords:
// status: incorrect
// cflags:   -d=newInst
//
// FAILREASON: Better error message needed.
//

model M
  Real x;
equation
  x = Integer(x);
end M;

// Result:
// SCodeInst.instFunction failed: Integer
// Error processing file: func5.mo
// Error: Error occurred while flattening model M
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
