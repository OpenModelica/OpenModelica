// name: InStreamNonCref1
// keywords: stream inStream connector
// status: incorrect
// cflags: -d=newInst
//

model InStreamNonCref1
  Real as = inStream(1);
end InStreamNonCref1;

// Result:
// Error processing file: InStreamNonCref1.mo
// [flattening/modelica/scodeinst/InStreamNonCref1.mo:8:3-8:24:writable] Error: First argument to inStream in component <REMOVE ME> must be a variable.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
