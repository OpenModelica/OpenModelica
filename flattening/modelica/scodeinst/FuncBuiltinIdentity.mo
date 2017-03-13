// name: FuncBuiltinIdentity
// keywords: identity
// status: correct
// cflags: -d=newInst
//
// Tests the builtin identity operator.
//

model FuncBuiltinIdentity
  Real x[3,3] = identity(3);
end FuncBuiltinIdentity;

// Result:
// Error processing file: FuncBuiltinIdentity.mo
// [lib/omc/ModelicaBuiltin.mo:139:3-139:47:writable] Error: Dimensions must be parameter or constant expression (in arraySize).
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
