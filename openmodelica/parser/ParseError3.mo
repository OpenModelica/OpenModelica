// name: ParseError3
// status: incorrect
//

model ParseError3
equation
  when time > 1.0 then
    assert;
  end when;
end ParseError3;

// Result:
// Error processing file: ParseError3.mo
// Failed to parse file: ParseError3.mo!
//
// [openmodelica/parser/ParseError3.mo:8:5-8:10:writable] Error: Parse error: A singleton expression in an equation section is required to be a function call
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
// Failed to parse file: ParseError3.mo!
//
// Execution failed!
// endResult
