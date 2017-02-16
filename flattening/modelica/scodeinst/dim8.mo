// name: dim8.mo
// keywords:
// status: incorrect
// cflags: -d=newInst
//

model M
  Integer x;
  Real y[x];
end M;

// Result:
// Error processing file: dim8.mo
// [flattening/modelica/scodeinst/dim8.mo:9:3-9:12:writable] Error: Dimensions must be parameter or constant expression (in x).
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
