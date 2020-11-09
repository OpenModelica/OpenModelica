// name:     Declaration3
// keywords: declaration
// status:   incorrect
// cflags: -d=-newInst
//
// Misuse of component attributes.
//

class Declaration3
  constant parameter Real x;
end Declaration3;

// Result:
// Error processing file: Declaration3.mo
// Failed to parse file: Declaration3.mo!
//
// [openmodelica/parser/Declaration3.mo:10:12-10:21:writable] Error: No viable alternative near token: parameter
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
// Failed to parse file: Declaration3.mo!
//
// Execution failed!
// endResult
