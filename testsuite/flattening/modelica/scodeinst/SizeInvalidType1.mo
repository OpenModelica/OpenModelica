// name: SizeInvalidType1
// keywords: size
// status: incorrect
// cflags: -d=newInst
//
// Tests the builtin size operator.
//

model SizeInvalidType1
  Real x[3];
  Integer y = size(x, "1");
end SizeInvalidType1;

// Result:
// Error processing file: SizeInvalidType1.mo
// [flattening/modelica/scodeinst/SizeInvalidType1.mo:11:3-11:27:writable] Error: Type mismatch for positional argument 2 in size (dim="1"). The argument has type:
//   String
// expected type:
//   Integer
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
