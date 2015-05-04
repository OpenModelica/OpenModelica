// name: IfElseIf
// status: incorrect

model IfElseIf
equation
  if cond then
    abc();
  else if cond then
    def();
  end if;
end IfElseIf;

// Result:
// Error processing file: IfElseIf.mo
// Failed to parse file: IfElseIf.mo!
//
// [openmodelica/parser/IfElseIf.mo:11:1-11:13:writable] Error: Parse error: Expected 'end if'; did you use a nested 'else if' instead of 'elseif'?
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
// Failed to parse file: IfElseIf.mo!
//
// Execution failed!
// endResult
