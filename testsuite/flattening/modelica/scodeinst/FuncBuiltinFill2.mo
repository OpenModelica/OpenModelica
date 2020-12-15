// name: FuncBuiltinFill2
// keywords: fill
// status: incorrect
// cflags: -d=newInst
//
// Tests the builtin fill operator.
//

model FuncBuiltinFill2
  Integer n = 3;
  Real x[3] = fill(0, n);
end FuncBuiltinFill2;

// Result:
// Error processing file: FuncBuiltinFill2.mo
// [flattening/modelica/scodeinst/FuncBuiltinFill2.mo:11:3-11:25:writable] Error: Expression ‘n‘ that determines the size of dimension ‘1‘ of ‘fill(0, n)‘ is not an evaluable parameter expression.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
