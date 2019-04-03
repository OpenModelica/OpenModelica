// name: SizeInvalidIndex2
// keywords: size
// status: incorrect
// cflags: -d=newInst
//
// Tests the builtin size operator.
//

model SizeInvalidIndex2
  Real x[2, 3];
  Integer y = size(x, -1);
end SizeInvalidIndex2;

// Result:
// Error processing file: SizeInvalidIndex2.mo
// [flattening/modelica/scodeinst/SizeInvalidIndex2.mo:11:3-11:26:writable] Error: Invalid index -1 in call to size of x, valid index interval is [1,2].
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
