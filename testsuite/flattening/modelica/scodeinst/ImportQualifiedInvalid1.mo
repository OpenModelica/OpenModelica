// name:     ImportQualifiedInvalid1
// keywords: qualified import
// status:   incorrect
//
// Checks that an error is output for missing qualified imports.
//

model ImportQualifiedInvalid1
  import P.M;
  M m;
end ImportQualifiedInvalid1;

// Result:
// Error processing file: ImportQualifiedInvalid1.mo
// [flattening/modelica/scodeinst/ImportQualifiedInvalid1.mo:9:3-9:13:writable] Error: Import P.M not found in scope <top>.
// [flattening/modelica/scodeinst/ImportQualifiedInvalid1.mo:10:3-10:6:writable] Error: Class M not found in scope ImportQualifiedInvalid1.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
