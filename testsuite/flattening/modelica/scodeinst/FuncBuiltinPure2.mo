// name:     FuncBuiltinPure2
// keywords:
// status:   incorrect
//
//

model FuncBuiltinPure2
  Real x = pure(1.0);
end FuncBuiltinPure2;

// Result:
// Error processing file: FuncBuiltinPure2.mo
// [flattening/modelica/scodeinst/FuncBuiltinPure2.mo:8:3-8:21:writable] Error: The argument to 'pure' must be a function call expression.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
