// name:     Assign4
// keywords: parse error
// status:   incorrect
//

model Assign4
equation
  x := res;
  annotation(__OpenModelica_commandLineOptions="-d=-newInst");
end Assign4;

// Result:
// Error processing file: Assign4.mo
// Failed to parse file: Assign4.mo!
//
// [openmodelica/parser/Assign4.mo:8:5-8:6:writable] Error: Parse error: Equations can not contain assignments (':='), use equality ('=') instead
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
// Failed to parse file: Assign4.mo!
//
// Execution failed!
// endResult
