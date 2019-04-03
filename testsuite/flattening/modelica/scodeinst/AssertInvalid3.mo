// name: AssertInvalid3
// keywords:
// status: incorrect
// cflags: -d=newInst
//

model AssertInvalid3
equation
  assert(false, "message", 1);
end AssertInvalid3;

// Result:
// Error processing file: AssertInvalid3.mo
// [flattening/modelica/scodeinst/AssertInvalid3.mo:9:3-9:30:writable] Error: Type mismatch for positional argument 3 in assert(level=1). The argument has type:
//   Integer
// expected type:
//   enumeration AssertionLevel(error, warning)
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
