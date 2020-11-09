// name:     ImplicitRangeReductionInvalid1
// keywords: reductions implicit range
// status:   incorrect
// cflags: -d=-newInst
//
// Tests deduction of implicit iteration ranges in reductions.
//

model ImplicitRangeReductionInvalid1
  Real x[3] = {1 for i};
end ImplicitRangeReductionInvalid1;

// Result:
// Error processing file: ImplicitRangeReductionInvalid1.mo
// [flattening/modelica/operators/ImplicitRangeReductionInvalid1.mo:10:3-10:24:writable] Error: Identifier i of implicit for iterator must be present as array subscript in the loop body.
// Error: Error occurred while flattening model ImplicitRangeReductionInvalid1
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
