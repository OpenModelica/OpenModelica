// name:     FunctionInvalidVar1
// keywords: function
// status:   incorrect
//
// Checks restrictions on function variable types.
//

model M
  Real r;
end M;

function F
  input M m;
end F;

model FunctionInvalidVar1
  M m;
algorithm
  F(m);
end FunctionInvalidVar1;

// Result:
// Error processing file: FunctionInvalidVar1.mo
// [flattening/modelica/algorithms-functions/FunctionInvalidVar1.mo:13:3-13:12:writable] Error: Invalid type M for function component m.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
