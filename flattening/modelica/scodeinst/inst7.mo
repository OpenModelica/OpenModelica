// name: inst7.mo
// keywords:
// status: correct
// cflags:   -d=newInst
//
// FAILREASON: Typing of x.start fails. Should this be allowed?
//


model M
  Real x(start = 2.0);
  Real y = x.start;
end M;

// Result:
// Failed to type cref x.start
// SCodeInst.instClass failed
// Error processing file: test2.mo
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
