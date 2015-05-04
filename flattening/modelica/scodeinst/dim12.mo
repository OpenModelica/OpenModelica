// name: dim12.mo
// keywords:
// status: incorrect
// cflags:   +d=scodeInst
//
// FAILREASON: Not good enough error message.
//


model M
  Real x[:];
end M;

// Result:
// SCodeInst.instClass failed
// Error processing file: dim12.mo
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
