// name: inst5.mo
// keywords:
// status: incorrect
// cflags:   -d=newInst
//

model M
  Real x;
  x y;
end M;

// Result:
// Error processing file: inst5.mo
// [flattening/modelica/scodeinst/inst5.mo:9:3-9:6:writable] Error: Expected x to be a class, but found component instead.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
