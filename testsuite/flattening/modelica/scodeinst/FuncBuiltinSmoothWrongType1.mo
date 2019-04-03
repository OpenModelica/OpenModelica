// name: FuncBuiltinSmoothWrongType1
// keywords: smooth
// status: incorrect
// cflags: -d=newInst
//
// Tests the builtin smooth operator.
//

model FuncBuiltinSmoothWrongType1
  parameter Integer k = 1;
  String s;
  Real y = smooth(k, s);
end FuncBuiltinSmoothWrongType1;

// Result:
// Error processing file: FuncBuiltinSmoothWrongType1.mo
// [flattening/modelica/scodeinst/FuncBuiltinSmoothWrongType1.mo:12:3-12:24:writable] Error: Type mismatch for positional argument 2 in smooth(=s). The argument has type:
//   String
// expected type:
//   Real
//   Real[:, ...]
//   Real record
//   Real record[:, ...]
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
