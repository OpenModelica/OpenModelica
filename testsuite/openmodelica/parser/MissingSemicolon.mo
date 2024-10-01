// name: MissingSemicolon
// status: incorrect
//
class abc
  annotation(__OpenModelica_commandLineOptions="-d=-newInst");
end abc

// Result:
// Error processing file: MissingSemicolon.mo
// Failed to parse file: MissingSemicolon.mo!
//
// [openmodelica/parser/MissingSemicolon.mo:20:0-20:0:writable] Error: Parser error: Unexpected token near:  (<EOF>)
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
// Failed to parse file: MissingSemicolon.mo!
//
// Execution failed!
// endResult
