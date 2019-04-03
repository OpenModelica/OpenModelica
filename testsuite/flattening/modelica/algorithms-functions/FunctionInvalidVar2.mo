// name:     FunctionInvalidVar2
// keywords: function
// status:   incorrect
//
// Checks restrictions on function variable types.
//

connector C
  Real r;
  flow Real f;
end C;

function F
  input C c;
end F;

model FunctionInvalidVar2
  C c;
algorithm
  F(c);
end FunctionInvalidVar2;

// Result:
// Error processing file: FunctionInvalidVar2.mo
// [flattening/modelica/algorithms-functions/FunctionInvalidVar2.mo:14:3-14:12:writable] Error: Invalid type .C for function component c.
// [flattening/modelica/algorithms-functions/FunctionInvalidVar2.mo:20:3-20:7:writable] Error: Class F not found in scope FunctionInvalidVar2 (looking for a function or record).
// Error: Error occurred while flattening model FunctionInvalidVar2
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
