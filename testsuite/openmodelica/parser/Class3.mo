// name:     Class3
// keywords:
// status:   incorrect
//
// The end must have the same identifier as the head.
//

class Class3
  Real x = 17.0;
  annotation(__OpenModelica_commandLineOptions="-d=-newInst");
end WrongEnd;
// Result:
// Error processing file: Class3.mo
// Failed to parse file: Class3.mo!
//
// [openmodelica/parser/Class3.mo:8:7-11:12:writable] Error: Parse error: The identifier at start and end are different
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
// Failed to parse file: Class3.mo!
//
// Execution failed!
// endResult
