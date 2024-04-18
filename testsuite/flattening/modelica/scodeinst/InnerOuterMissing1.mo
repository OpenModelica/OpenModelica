// name: InnerOuterMissing1
// keywords:
// status: incorrect
// cflags: -d=newInst
//

model InnerOuterMissing1
  outer Real x;
end InnerOuterMissing1;

// Result:
// Error processing file: InnerOuterMissing1.mo
// [flattening/modelica/scodeinst/InnerOuterMissing1.mo:8:3-8:15:writable] Error: The model can't be instantiated due to top-level outer element 'x', it may only be used as part of a simulation model.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
