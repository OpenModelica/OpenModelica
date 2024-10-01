// name: SubscriptTooMany1
// status: incorrect
//

model SubscriptTooMany1
  Real x[3] = {1, 2, 3};
  Real y = x[2, 2];
end SubscriptTooMany1;

// Result:
// Error processing file: SubscriptTooMany1.mo
// [flattening/modelica/scodeinst/SubscriptTooMany1.mo:7:3-7:19:writable] Error: Wrong number of subscripts in x[2, 2] (2 subscripts for 1 dimensions).
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
