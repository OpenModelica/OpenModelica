// name: TimeKeyword
// keywords: Modelica 3.7 time keyword
// status: incorrect
// cflags: -d=newInst --std=3.7 --strict
// suite: antlr
//
// time is a keyword since Modelica 3.7.
//

model TimeKeyword
  Real time;
end TimeKeyword;

// Result:
// Error processing file: TimeKeyword.mo
// Failed to parse file: TimeKeyword.mo!
//
// [openmodelica/parser/TimeKeyword.mo:11:3-11:7:writable] Error: No viable alternative near token: Real
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
// Failed to parse file: TimeKeyword.mo!
//
// Execution failed!
// endResult
