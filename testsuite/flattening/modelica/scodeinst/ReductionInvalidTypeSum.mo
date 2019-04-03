// name: ReductionInvalidTypeSum
// keywords: reduction
// status: incorrect
// cflags: -d=newInst
//
// Tests the builtin reduction operators.
//

model ReductionInvalidTypeSum
  Real x = sum("test" for i in 1:3);
end ReductionInvalidTypeSum;

// Result:
// Error processing file: ReductionInvalidTypeSum.mo
// [flattening/modelica/scodeinst/ReductionInvalidTypeSum.mo:10:3-10:36:writable] Error: Invalid expression ‘"test"‘ of type String in sum reduction, expected Integer or Real.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
