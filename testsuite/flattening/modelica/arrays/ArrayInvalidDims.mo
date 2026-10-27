// name: ArrayInvalidDims
// keywords: array invalid dimensions
// status: incorrect
//
// Checks that an error message is generated if the arguments to array have
// different dimensions.
//

model ArrayInvalidDims
  Real r[:,:] = array({1,2,3},{3,4});
end ArrayInvalidDims;

// Result:
// Error processing file: ArrayInvalidDims.mo
// [flattening/modelica/arrays/ArrayInvalidDims.mo:10:3-10:37:writable] Error: Array types mismatch. Argument 2 ({3, 4}) has type Integer[2] whereas previous arguments have type Integer[3].
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
