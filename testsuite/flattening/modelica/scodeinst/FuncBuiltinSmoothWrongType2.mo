// name: FuncBuiltinSmoothWrongType2
// keywords: smooth
// status: incorrect
// cflags: -d=newInst
//
// Tests the builtin smooth operator.
//

model FuncBuiltinSmoothWrongType2
  parameter Real k = 1;
  Real x;
  Real y = smooth(k, x);
end FuncBuiltinSmoothWrongType2;

// Result:
// Error processing file: FuncBuiltinSmoothWrongType2.mo
// [flattening/modelica/scodeinst/FuncBuiltinSmoothWrongType2.mo:12:3-12:24:writable] Error: Type mismatch for positional argument 1 in smooth(=k). The argument has type:
//   Real
// expected type:
//   Integer
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
