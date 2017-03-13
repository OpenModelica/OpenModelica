// name: FuncBuiltinCross
// keywords: cross
// status: correct
// cflags: -d=newInst
//
// Tests the builtin cross operator.
//

model FuncBuiltinCross
  Real x[3] = cross({1, 2, 3}, {4, 5, 6});
end FuncBuiltinCross;

// Result:
// Error processing file: FuncBuiltinCross.mo
// Error: Internal error Instantiation of FuncBuiltinCross failed with no error message.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
