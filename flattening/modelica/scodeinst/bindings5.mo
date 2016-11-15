// name: bindings5.mo
// keywords:
// status: incorrect
// cflags: -d=newInst
//

model N
  Real r;
end N;

model M
  N n(each r = 1.0);
end M;

// Result:
// Error processing file: bindings5.mo
// [flattening/modelica/scodeinst/bindings5.mo:12:12-12:19:writable] Error: 'each' used when modifying non-array element n.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
