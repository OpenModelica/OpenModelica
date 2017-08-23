// name: SizeInvalidType2
// keywords: size
// status: incorrect
// cflags: -d=newInst
//
// Tests the builtin size operator.
//

model SizeInvalidType2
  Real x[3];
  Integer y = size("array", 1);
end SizeInvalidType2;

// Result:
// Error processing file: SizeInvalidType2.mo
// [flattening/modelica/scodeinst/SizeInvalidType2.mo:11:3-11:31:writable] Error: The first argument of size must be an array expression.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
