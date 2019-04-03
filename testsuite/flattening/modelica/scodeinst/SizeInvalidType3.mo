// name: SizeInvalidType3
// keywords: size
// status: incorrect
// cflags: -d=newInst
//
// Tests the builtin size operator.
//

model SizeInvalidType3
  Real x[3];
  Integer y = size(x[1], 1);
end SizeInvalidType3;

// Result:
// Error processing file: SizeInvalidType3.mo
// [flattening/modelica/scodeinst/SizeInvalidType3.mo:11:3-11:28:writable] Error: The first argument of size must be an array expression.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
