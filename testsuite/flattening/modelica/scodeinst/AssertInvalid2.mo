// name: AssertInvalid2
// keywords:
// status: incorrect
// cflags: -d=newInst
//

model AssertInvalid2
equation
  assert(false, 1);
end AssertInvalid2;

// Result:
// Error processing file: AssertInvalid2.mo
// [flattening/modelica/scodeinst/AssertInvalid2.mo:9:3-9:19:writable] Error: Type mismatch for positional argument 2 in assert(message=1). The argument has type:
//   Integer
// expected type:
//   String
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
