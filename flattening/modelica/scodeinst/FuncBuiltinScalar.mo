// name: FuncBuiltinScalar
// keywords: scalar
// status: correct
// cflags: -d=newInst
//
// Tests the builtin scalar operator.
//

model FuncBuiltinScalar
  Real r1 = scalar({{1}});
  Real r2 = scalar(4);
  Real r3 = scalar({{{{5}}}});
end FuncBuiltinScalar;

// Result:
// Error processing file: FuncBuiltinScalar.mo
// [flattening/modelica/scodeinst/FuncBuiltinScalar.mo:10:3-10:26:writable] Error: No matching function found for scalar({{1}}) in component <REMOVE ME>
// candidates are :
//   scalar()
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
