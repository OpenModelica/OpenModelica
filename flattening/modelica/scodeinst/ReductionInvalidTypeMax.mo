// name: ReductionInvalidTypeMax
// keywords: reduction
// status: incorrect
// cflags: -d=newInst
//
// Tests the builtin reduction operators.
//

model ReductionInvalidTypeMax
  Real x = max("test" for i in 1:3);
end ReductionInvalidTypeMax;

// Result:
// Error processing file: ReductionInvalidTypeMax.mo
// [flattening/modelica/scodeinst/ReductionInvalidTypeMax.mo:10:3-10:36:writable] Error: Invalid expression ‘"test"‘ of type String in max reduction, expected scalar enumeration, Boolean, Integer or Real.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
