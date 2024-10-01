// name:     ParseError1
// keywords: parse error
// status:   incorrect
//
// Parsing error message.
//

model ParseError1
  Real x,y,;
  annotation(__OpenModelica_commandLineOptions="-d=-newInst");
end ParseError1;

// Result:
// Error processing file: ParseError1.mo
// Failed to parse file: ParseError1.mo!
//
// [openmodelica/parser/ParseError1.mo:9:12-10:2:writable] Error: No viable alternative near token: ;
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
// Failed to parse file: ParseError1.mo!
//
// Execution failed!
// endResult
