// name:     ImportFullyQualified
// keywords: import
// status:   incorrect
// cflags: -d=-newInst
//
// Checks that fully qualified imports are rejected.
//

package P
end P;

model ImportFullyQualified
  import .P;
end ImportFullyQualified;

// Result:
// Error processing file: ImportFullyQualified.mo
// Failed to parse file: ImportFullyQualified.mo!
//
// [openmodelica/parser/ImportFullyQualified.mo:13:10-13:10:writable] Error: No viable alternative near token: .
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
// Failed to parse file: ImportFullyQualified.mo!
//
// Execution failed!
// endResult
