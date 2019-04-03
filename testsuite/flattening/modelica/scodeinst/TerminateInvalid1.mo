// name: TerminateInvalid1
// keywords:
// status: incorrect
// cflags: -d=newInst
//

model TerminateInvalid1
equation
  terminate(1.0);
end TerminateInvalid1;

// Result:
// Error processing file: TerminateInvalid1.mo
// [flattening/modelica/scodeinst/TerminateInvalid1.mo:9:3-9:17:writable] Error: Type mismatch for positional argument 1 in terminate(message=1.0). The argument has type:
//   Real
// expected type:
//   String
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
