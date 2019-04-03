// name: BuiltinTimeSubscripted
// keywords:
// status: incorrect
// cflags:   -d=newInst
//
//

model BuiltinTimeSubscripted
  Real x = time[2];
end BuiltinTimeSubscripted;

// Result:
// Error processing file: BuiltinTimeSubscripted.mo
// [flattening/modelica/scodeinst/BuiltinTimeSubscripted.mo:9:3-9:19:writable] Error: Wrong number of subscripts in time[2] (1 subscripts for 0 dimensions).
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
