// name: SizeInvalidIndex4
// keywords: size
// status: incorrect
// cflags: -d=newInst
//
// Tests the builtin size operator.
//

model SizeInvalidIndex4
  Integer y = size({1, 2, 3}, 0);
end SizeInvalidIndex4;

// Result:
// Error processing file: SizeInvalidIndex4.mo
// [flattening/modelica/scodeinst/SizeInvalidIndex4.mo:10:3-10:33:writable] Error: Invalid index 0 in call to size of {1, 2, 3}, valid index interval is [1,1].
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
