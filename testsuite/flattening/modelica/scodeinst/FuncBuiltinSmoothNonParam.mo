// name: FuncBuiltinSmoothNonParam
// keywords: smooth
// status: incorrect
//
// Tests the builtin smooth operator.
//

model FuncBuiltinSmoothNonParam
  Integer k = 1;
  Real x = time;
  Real y = smooth(k, x);
end FuncBuiltinSmoothNonParam;

// Result:
// Error processing file: FuncBuiltinSmoothNonParam.mo
// [flattening/modelica/scodeinst/FuncBuiltinSmoothNonParam.mo:11:3-11:24:writable] Error: Argument 1 of smooth must be a parameter expression, but k is continuous.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
