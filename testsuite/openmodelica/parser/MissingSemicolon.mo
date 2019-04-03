// name: MissingSemicolon
// status: incorrect
//
class abc
end abc

// Result:
// Error processing file: MissingSemicolon.mo
// Failed to parse file: MissingSemicolon.mo!
//
// [openmodelica/parser/MissingSemicolon.mo:19:0-19:0:writable] Error: Parser error: Unexpected token near:  (<EOF>)
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
// Failed to parse file: MissingSemicolon.mo!
//
// Execution failed!
// endResult
