// name:     EmptyArray
// keywords: array, constructor, empty
// status:   incorrect
//
// Checks that empty array constructors are not allowed, as per 10.4 in the
// Modelica 3.2 specification.
//

model EmptyArray
  Real r[:] = {};
end EmptyArray;

// Result:
// Error processing file: EmptyArray.mo
// Failed to parse file: EmptyArray.mo!
//
// [flattening/modelica/arrays/EmptyArray.mo:10:15-10:16:writable] Error: Parse error: Empty array constructors are not valid in Modelica.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
// Failed to parse file: EmptyArray.mo!
//
// Execution failed!
// endResult
