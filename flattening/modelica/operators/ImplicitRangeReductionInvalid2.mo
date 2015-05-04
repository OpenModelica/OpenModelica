// name:     ImplicitRangeReductionInvalid2
// keywords: reductions implicit range
// status:   incorrect
//
// Tests deduction of implicit iteration ranges in reductions.
//

model ImplicitRangeReductionInvalid2
  Real x[3] = {i for i};
end ImplicitRangeReductionInvalid2;

// Result:
// Error processing file: ImplicitRangeReductionInvalid2.mo
// [flattening/modelica/operators/ImplicitRangeReductionInvalid2.mo:9:3-9:24:writable] Error: Identifier i of implicit for iterator must be present as array subscript in the loop body.
// Error: Error occurred while flattening model ImplicitRangeReductionInvalid2
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
