// name: FuncBuiltinVectorWrongType1
// keywords: vector
// status: incorrect
// cflags: -d=newInst
//
// Tests the builtin vector operator.
//

model FuncBuiltinVectorWrongType1
  Real x[3] = vector({{1, 2}, {2, 2}, {3, 2}});
end FuncBuiltinVectorWrongType1;

// Result:
// Error processing file: FuncBuiltinVectorWrongType1.mo
// [flattening/modelica/scodeinst/FuncBuiltinVectorWrongType1.mo:10:3-10:47:writable] Error: Invalid dimensions Integer[3, 2] in vector({{1, 2}, {2, 2}, {3, 2}}), no more than one dimension may have size > 1.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
