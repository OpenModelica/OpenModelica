// name: dim12.mo
// keywords:
// status: incorrect
// cflags:   -d=newInst
//
// FAILREASON: Not good enough error message.
//


model M
  Real x[:];
end M;

// Result:
// Error processing file: dim12.mo
// [flattening/modelica/scodeinst/dim12.mo:11:3-11:12:writable] Error: Failed to deduce dimension 1 of x due to missing binding equation.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
