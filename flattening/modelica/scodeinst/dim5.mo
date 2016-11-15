// name: dim5.mo
// keywords:
// status: incorrect
// cflags:   -d=newInst
//
// FAILREASON: Not good enough error message.
//


model M
  parameter Integer i = size(x, 2);
  Real x[i, i + 2] = {{1, 2, 3}, {4, 5, 6}};
end M;

// Result:
// Failed to type cref i
// SCodeInst.instClass failed
// Error processing file: dim5.mo
// Error: Internal error Found cyclic dependencies, but failed to show error.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
