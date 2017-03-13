// name: FuncBuiltinVector
// keywords: vector
// status: correct
// cflags: -d=newInst
//
// Tests the builtin vector operator.
//

model FuncBuiltinVector
  Real x[1] = vector(1);
  Real y[3] = vector({{1}, {2}, {3}});
  Real z[3] = vector({1, 2, 3});
end FuncBuiltinVector;

// Result:
// Error processing file: FuncBuiltinVector.mo
// [flattening/modelica/scodeinst/FuncBuiltinVector.mo:10:3-10:24:writable] Error: No matching function found for vector(1) in component <REMOVE ME>
// candidates are :
//   vector()
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
