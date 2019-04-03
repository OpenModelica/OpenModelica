// name: FuncBuiltinInitial2
// keywords: initial
// status: incorrect
// cflags: -d=newInst
//
// Tests the builtin initial operator.
//

model FuncBuiltinInitial2
  parameter Boolean b = initial();
end FuncBuiltinInitial2;

// Result:
// Error processing file: FuncBuiltinInitial2.mo
// [flattening/modelica/scodeinst/FuncBuiltinInitial2.mo:10:3-10:34:writable] Error: Component b of variability parameter has binding 'initial()' of higher variability discrete.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
