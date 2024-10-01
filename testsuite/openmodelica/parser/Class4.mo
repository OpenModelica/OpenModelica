// name:     Class4
// keywords:
// status:   incorrect
//
// end should be followed by Class4.
//

class Class4

  annotation(__OpenModelica_commandLineOptions="-d=-newInst");
end;

// Result:
// Error processing file: Class4.mo
// Failed to parse file: Class4.mo!
//
// [openmodelica/parser/Class4.mo:11:1-11:3:writable] Error: No viable alternative near token: end
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
// Failed to parse file: Class4.mo!
//
// Execution failed!
// endResult
