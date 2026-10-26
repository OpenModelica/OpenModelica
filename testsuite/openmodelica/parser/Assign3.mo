// name:     Assign3
// keywords: parse error
// status:   incorrect
//

model Assign3
algorithm
  (x,y,z) := res;
end Assign3;

// Result:
// Error processing file: Assign3.mo
// Failed to parse file: Assign3.mo!
//
// [openmodelica/parser/Assign3.mo:8:3-8:16:writable] Error: Parse error: Modelica assignment statements are either on the form 'component_reference := expression' or '( output_expression_list ) := function_call'
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
// Failed to parse file: Assign3.mo!
//
// Execution failed!
// endResult
