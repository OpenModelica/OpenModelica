// name: FunctionStreamPrefix
// keywords:
// status: incorrect
// cflags: -d=newInst
//

function f
  stream input Real x;
end f;

model FunctionStreamPrefix
algorithm
  f(1.0);
end FunctionStreamPrefix;

// Result:
// Error processing file: FunctionStreamPrefix.mo
// [flattening/modelica/scodeinst/FunctionStreamPrefix.mo:8:3-8:22:writable] Error: Invalid prefix stream on formal parameter x.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
