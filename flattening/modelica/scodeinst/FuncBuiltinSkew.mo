// name: FuncBuiltinSkew
// keywords: skew
// status: correct
// cflags: -d=newInst
//
// Tests the builtin skew operator.
//

model FuncBuiltinSkew
  Real x[3, 3] = skew({1, 2, 3});
end FuncBuiltinSkew;

// Result:
// Error processing file: FuncBuiltinSkew.mo
// Error: Internal error Instantiation of FuncBuiltinSkew failed with no error message.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
