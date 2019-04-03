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
// [flattening/modelica/built-in-functions/Identity2.mo:9:3-9:34:writable] Error: First argument to identity in component <NO COMPONENT> must be Integer expression.
// Error: Error occurred while flattening model Identity2
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
