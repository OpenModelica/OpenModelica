// name: FuncBuiltinLinspace
// keywords: linspace
// status: correct
// cflags: -d=newInst
//
// Tests the builtin linspace operator.
//

model FuncBuiltinLinspace
  Real x[5] = linspace(2.0, 4.0, 5);
end FuncBuiltinLinspace;

// Result:
// Error processing file: FuncBuiltinLinspace.mo
// [lib/omc/ModelicaBuiltin.mo:302:3-302:47:writable] Error: Variable $array not found in scope linspace.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
