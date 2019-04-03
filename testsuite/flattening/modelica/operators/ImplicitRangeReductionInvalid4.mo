// name:     ImplicitRangeReductionInvalid4
// keywords: reductions implicit range
// status:   incorrect
//
// Tests deduction of implicit iteration ranges in reductions.
//

model ImplicitRangeReductionInvalid4
  Real x[3] = {1, 2, 3};
  Real y[4] = {1, 2, 3, 4};
  Real z[3] = {x[i] + y[i] for i};
end ImplicitRangeReductionInvalid4;

// Result:
// Error processing file: ImplicitRangeReductionInvalid4.mo
// [flattening/modelica/operators/ImplicitRangeReductionInvalid4.mo:11:3-11:34:writable] Error: Dimension 1 of y and 1 of x differs when trying to deduce implicit iteration range.
// Error: Error occurred while flattening model ImplicitRangeReductionInvalid4
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
