// name:     BuiltinTimeInvalid2
// keywords: time builtin
// status:   incorrect
//
// Checks that time is not a valid component name.
//

model BuiltinTimeInvalid2
  Real time = 1.0;
end BuiltinTimeInvalid2;

// Result:
// Error processing file: BuiltinTimeInvalid2.mo
// [flattening/modelica/declarations/BuiltinTimeInvalid2.mo:9:3-9:18:writable] Error: Identifier time is reserved for the built-in element with the same name.
// Error: Error occurred while flattening model BuiltinTimeInvalid2
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
