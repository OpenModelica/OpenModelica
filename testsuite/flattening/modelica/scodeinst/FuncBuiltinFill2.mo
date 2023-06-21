// name: FuncBuiltinFill2
// keywords: fill
// status: incorrect
// cflags: -d=newInst
//
// Tests the builtin fill operator.
//

model FuncBuiltinFill2
  Integer n = 3;
  Real x[1, 3] = fill(0, 1, n);
end FuncBuiltinFill2;

// Result:
// Error processing file: FuncBuiltinFill2.mo
// [flattening/modelica/scodeinst/FuncBuiltinFill2.mo:11:3-11:31:writable] Error: Expression 'n' that determines the size of dimension '2' of 'fill(0, 1, n)' is not an evaluable parameter expression.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
