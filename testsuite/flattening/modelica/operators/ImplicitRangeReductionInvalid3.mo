// name:     ImplicitRangeReductionInvalid3
// keywords: reductions implicit range
// status:   incorrect
// cflags: -d=-newInst
//
// Tests deduction of implicit iteration ranges in reductions.
//

model ImplicitRangeReductionInvalid3
  Real x[3] = {y[i] for i};
end ImplicitRangeReductionInvalid3;

// Result:
// Error processing file: ImplicitRangeReductionInvalid3.mo
// [flattening/modelica/operators/ImplicitRangeReductionInvalid3.mo:10:3-10:27:writable] Error: Variable y not found in scope .
// Error: Error occurred while flattening model ImplicitRangeReductionInvalid3
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
