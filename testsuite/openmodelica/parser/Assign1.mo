// name:     Assign1
// keywords: parse error
// status:   incorrect
// cflags: -d=-newInst
//

model Assign1
algorithm
  x = 3;
end Assign1;

// Result:
// Error processing file: Assign1.mo
// Failed to parse file: Assign1.mo!
//
// [openmodelica/parser/Assign1.mo:9:5-9:6:writable] Error: Parse error: Algorithms can not contain equations ('='), use assignments (':=') instead
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
// Failed to parse file: Assign1.mo!
//
// Execution failed!
// endResult
