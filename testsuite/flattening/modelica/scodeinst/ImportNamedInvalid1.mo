// name:     ImportNamedInvalid1
// keywords: named import
// status:   incorrect
//
// Checks that an error is output for missing named imports.
//

model ImportNamedInvalid1
  import M = P.M;
  M m;
end ImportNamedInvalid1;

// Result:
// Error processing file: ImportNamedInvalid1.mo
// [flattening/modelica/scodeinst/ImportNamedInvalid1.mo:9:3-9:17:writable] Error: Import P.M not found in scope <top>.
// [flattening/modelica/scodeinst/ImportNamedInvalid1.mo:10:3-10:6:writable] Error: Class M not found in scope ImportNamedInvalid1.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
