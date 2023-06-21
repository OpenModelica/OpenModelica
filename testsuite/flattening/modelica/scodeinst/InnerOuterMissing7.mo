// name: InnerOuterMissing7
// keywords:
// status: incorrect
// cflags: -d=newInst
//

model A
  outer Real x;
end A;

model InnerOuterMissing7
  A a;
  Real x;
end InnerOuterMissing7;

// Result:
// Error processing file: InnerOuterMissing7.mo
// [flattening/modelica/scodeinst/InnerOuterMissing7.mo:13:3-13:9:writable] Notification: From here:
// [flattening/modelica/scodeinst/InnerOuterMissing7.mo:8:3-8:15:writable] Error: An inner declaration for outer element 'x' could not be found, and could not be automatically generated due to an existing declaration of that name.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
