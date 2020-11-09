// name:     Assign4
// keywords: parse error
// status:   incorrect
// cflags: -d=-newInst
//

model Assign4
equation
  x := res;
end Assign4;

// Result:
// Error processing file: Assign4.mo
// Failed to parse file: Assign4.mo!
//
// [openmodelica/parser/Assign4.mo:9:5-9:6:writable] Error: Parse error: Equations can not contain assignments (':='), use equality ('=') instead
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
// Failed to parse file: Assign4.mo!
//
// Execution failed!
// endResult
