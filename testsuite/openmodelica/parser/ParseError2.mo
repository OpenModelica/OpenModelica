// name:     ParseError2
// keywords: parse error
// status:   incorrect
// cflags: -d=-newInst
//
// Parsing error message.
//

model ParseError2
  Real 1x;
end ParseError2;

// Result:
// Error processing file: ParseError2.mo
// Failed to parse file: ParseError2.mo!
//
// [openmodelica/parser/ParseError2.mo:10:3-10:7:writable] Error: No viable alternative near token: Real
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
// Failed to parse file: ParseError2.mo!
//
// Execution failed!
// endResult
