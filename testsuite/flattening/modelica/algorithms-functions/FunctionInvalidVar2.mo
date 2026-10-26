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
// [flattening/modelica/algorithms-functions/FunctionInvalidVar2.mo:14:3-14:12:writable] Warning: Connector c is not balanced: The number of potential variables (0) is not equal to the number of flow variables (1).
// [flattening/modelica/algorithms-functions/FunctionInvalidVar2.mo:14:3-14:12:writable] Error: Invalid type C for function component c.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
