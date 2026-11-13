// name: TypeClass3
// keywords: type
// status: incorrect
//
// Tests that only a type or a connector may extend a type.
//

model M
  extends Real;
end M;

model TypeClass3
  M m;
equation
  m = 1;
end TypeClass3;

// Result:
// Error processing file: TypeClass3.mo
// [flattening/modelica/types/TypeClass3.mo:8:1-10:6:writable] Error: Class specialization violation: M is a model, not a type.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
