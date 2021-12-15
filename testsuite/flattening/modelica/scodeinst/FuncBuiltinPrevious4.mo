// name: FuncBuiltinPrevious4
// keywords: pre
// status: incorrect
// cflags: -d=newInst
//
// Tests the builtin previous operator.
//

function f
end f;

model FuncBuiltinPrevious4
  Real x;
equation
  x = previous(f);
end FuncBuiltinPrevious4;

// Result:
// Error processing file: FuncBuiltinPrevious4.mo
// [flattening/modelica/scodeinst/FuncBuiltinPrevious4.mo:15:3-15:18:writable] Error: Type mismatch for positional argument 1 in previous(u=f). The argument has type:
//   f<function>() => ()
// expected type:
//   ComponentExpression
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
