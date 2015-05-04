// name: const9.mo
// keywords:
// status: incorrect
// cflags:   +d=scodeInst
//


constant Integer i = 0;

model A
  Integer j = i;
end A;

// Result:
// Error processing file: const9.mo
// Failed to parse file: const9.mo!
//
// [flattening/modelica/scodeinst/const9.mo:8:1-8:9:writable] Error: Parser error: Unexpected token near: constant (CONSTANT)
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
// Failed to parse file: const9.mo!
//
// Execution failed!
// endResult
