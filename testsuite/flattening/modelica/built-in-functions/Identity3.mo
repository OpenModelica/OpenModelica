// name: Identity3
// keywords: identity
// status: incorrect
//
// Tests the built in operator identity.
//

model Identity3
  Integer a[2, 2] = identity(2, 2);
end Identity3;

// Result:
// Error processing file: Identity3.mo
// [flattening/modelica/built-in-functions/Identity3.mo:9:3-9:35:writable] Error: Wrong number of arguments to identity.
// Error: Error occurred while flattening model Identity3
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
