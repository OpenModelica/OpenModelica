// name: inst7.mo
// keywords:
// status: incorrect
// cflags:   -d=newInst
//
//


model M
  Real x(start = 2.0);
  Real y = x.start;
end M;

// Result:
// Error processing file: inst7.mo
// [flattening/modelica/scodeinst/inst7.mo:11:3-11:19:writable] Error: Variable start not found in scope x.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
