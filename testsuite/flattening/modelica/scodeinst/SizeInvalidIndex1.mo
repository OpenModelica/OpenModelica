// name: SizeInvalidIndex1
// keywords: size
// status: incorrect
// cflags: -d=newInst
//
// Tests the builtin size operator.
//

model SizeInvalidIndex1
  Real x[2, 3];
  Integer y = size(x, 3);
end SizeInvalidIndex1;

// Result:
// Error processing file: SizeInvalidIndex1.mo
// [flattening/modelica/scodeinst/SizeInvalidIndex1.mo:11:3-11:25:writable] Error: Invalid index 3 in call to size of x, valid index interval is [1,2].
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
