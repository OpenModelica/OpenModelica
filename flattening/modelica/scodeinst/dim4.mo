// name: dim4.mo
// keywords:
// status: incorrect
// cflags:   -d=newInst
//
// FAILREASON: Not good enough error message.
//


model M
  Real x[size(x,1)] = {1, 2, 3};
end M;

// Result:
// Found dimension loop
// Error processing file: dim4.mo
// Error: Error occurred while flattening model M
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
