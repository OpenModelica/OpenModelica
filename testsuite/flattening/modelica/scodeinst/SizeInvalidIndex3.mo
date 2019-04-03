// name: SizeInvalidIndex3
// keywords: size
// status: incorrect
// cflags: -d=newInst
//
// Tests the builtin size operator.
//

model SizeInvalidIndex3
  Integer y = size({1, 2, 3}, 2);
end SizeInvalidIndex3;

// Result:
// Error processing file: SizeInvalidIndex3.mo
// [flattening/modelica/scodeinst/SizeInvalidIndex3.mo:10:3-10:33:writable] Error: Invalid index 2 in call to size of {1, 2, 3}, valid index interval is [1,1].
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
