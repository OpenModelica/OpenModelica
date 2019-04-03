// name: ReductionInvalidTypeMin
// keywords: reduction
// status: incorrect
// cflags: -d=newInst
//
// Tests the builtin reduction operators.
//

model ReductionInvalidTypeMin
  Real x = min({1, 2, 3} for i in 1:3);
end ReductionInvalidTypeMin;

// Result:
// Error processing file: ReductionInvalidTypeMin.mo
// [flattening/modelica/scodeinst/ReductionInvalidTypeMin.mo:10:3-10:39:writable] Error: Invalid expression ‘{1, 2, 3}‘ of type Integer[3] in min reduction, expected scalar enumeration, Boolean, Integer or Real.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
