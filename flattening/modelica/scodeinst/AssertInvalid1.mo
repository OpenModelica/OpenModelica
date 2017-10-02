// name: AssertInvalid1
// keywords:
// status: incorrect
// cflags: -d=newInst
//

model AssertInvalid1
equation
  assert("true", "message");
end AssertInvalid1;

// Result:
// Error processing file: AssertInvalid1.mo
// [flattening/modelica/scodeinst/AssertInvalid1.mo:9:3-9:28:writable] Error: Type mismatch for positional argument 1 in assert(condition="true"). The argument has type:
//   String
// expected type:
//   Boolean
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
