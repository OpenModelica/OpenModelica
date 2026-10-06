// name: AssignModifier
// keywords: Modelica 3.7 modifier
// status: incorrect
// cflags: -d=newInst --std=3.7 --strict
//
// := in modifiers was removed in Modelica 3.7.
//

model AssignModifier
  Real x := 1;
end AssignModifier;

// Result:
// Error processing file: AssignModifier.mo
// Failed to parse file: AssignModifier.mo!
//
// [openmodelica/parser/AssignModifier.mo:10:10-10:14:writable] Error: Parse error: := in modifiers is not allowed since Modelica 3.7
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
// Failed to parse file: AssignModifier.mo!
//
// Execution failed!
// endResult
