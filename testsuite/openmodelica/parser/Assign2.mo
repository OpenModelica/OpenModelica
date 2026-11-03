// name:     Assign2
// keywords: parse error
// status:   incorrect
//

model Assign1
algorithm
  {x,y,z} := fn(1,2,3);
end Assign1;

// Result:
// Error processing file: Assign2.mo
// Failed to parse file: Assign2.mo!
//
// [openmodelica/parser/Assign2.mo:8:3-8:22:writable] Error: Parse error: Modelica assignment statements are either on the form 'component_reference := expression' or '( output_expression_list ) := function_call'
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
// Failed to parse file: Assign2.mo!
//
// Execution failed!
// endResult
