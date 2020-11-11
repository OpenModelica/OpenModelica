// name:     FunctionInvalidVar1
// keywords: function
// status:   incorrect
// cflags: -d=-newInst
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
// [flattening/modelica/algorithms-functions/FunctionInvalidVar1.mo:14:3-14:12:writable] Error: Invalid type .M for function component m.
// [flattening/modelica/algorithms-functions/FunctionInvalidVar1.mo:20:3-20:7:writable] Error: Class F not found in scope FunctionInvalidVar1 (looking for a function or record).
// Error: Error occurred while flattening model FunctionInvalidVar1
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
