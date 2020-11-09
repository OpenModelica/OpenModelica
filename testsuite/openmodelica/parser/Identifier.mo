// name: Identifier
// keywords: identifier
// status: incorrect
// cflags: -d=-newInst
//
// Using reserved words as identifiers
//

model Identifier
  Real model;
equation
  model = 2;
end Identifier;

// Result:
// Error processing file: Identifier.mo
// Failed to parse file: Identifier.mo!
//
// [openmodelica/parser/Identifier.mo:10:3-10:7:writable] Error: No viable alternative near token: Real
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
// Failed to parse file: Identifier.mo!
//
// Execution failed!
// endResult
