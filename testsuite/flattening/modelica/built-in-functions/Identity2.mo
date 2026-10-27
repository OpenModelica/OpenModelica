// name: Identity2
// keywords: identity
// status: incorrect
//
// Tests the built in operator identity.
//

model Identity2
  Integer a[2, 2] = identity(2.0);
end Identity2;

// Result:
// Error processing file: Identity2.mo
// [flattening/modelica/built-in-functions/Identity2.mo:9:3-9:34:writable] Error: Type mismatch for positional argument 1 in identity(arraySize=2.0). The argument has type:
//   Real
// expected type:
//   Integer
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
