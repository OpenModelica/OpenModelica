// name: dim6.mo
// keywords:
// status: incorrect
// cflags:   -d=newInst
//
// FAILREASON: Not good enough error message.
//


model M
  parameter Integer n = size(x, 1) ^ 5;
  Real x[n * size(x, 2), n] = {{1}};
end M;

// Result:
// Failed to type cref n
// SCodeInst.instClass failed
// Error processing file: dim6.mo
// Error: Internal error Found cyclic dependencies, but failed to show error.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
