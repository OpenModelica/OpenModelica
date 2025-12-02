// name: FuncBuiltinSmoothWrongArgs1
// keywords: smooth
// status: incorrect
//
// Tests the builtin smooth operator.
//

model FuncBuiltinSmoothWrongArgs1
  parameter Integer k = 1;
  Real x;
  Real y = smooth(k, x, x);
end FuncBuiltinSmoothWrongArgs1;

// Result:
// Error processing file: FuncBuiltinSmoothWrongArgs1.mo
// [flattening/modelica/scodeinst/FuncBuiltinSmoothWrongArgs1.mo:11:3-11:27:writable] Error: No matching function found for smooth(k, x, x).
// Candidates are:
//   smooth(Integer, Any) => Any
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
