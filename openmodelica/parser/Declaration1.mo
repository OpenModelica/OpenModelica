// name:     Declaration1
// keywords: declaration
// status:   incorrect
//
// Misuse of component attributes.
//

class Declaration1
  discrete constant Real x;
end Declaration1;

// Result:
// Error processing file: Declaration1.mo
// Failed to parse file: Declaration1.mo!
//
// [openmodelica/parser/Declaration1.mo:9:12-9:20:writable] Error: No viable alternative near token: constant
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
// Failed to parse file: Declaration1.mo!
//
// Execution failed!
// endResult
