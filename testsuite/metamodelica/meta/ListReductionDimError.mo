// name: ListReductionDimError
// cflags: +g=MetaModelica
// status: incorrect
// suite: metamodelica

model ListReductionDimError
  Real r[3];
equation
  r = {i for i in {-3,3}};
end ListReductionDimError;

// Result:
// Error processing file: ListReductionDimError.mo
// [metamodelica/meta/ListReductionDimError.mo:9:3-9:26:writable] Error: Type mismatch in equation r = {i for i in {-3, 3}} of type Real[3] = Integer[2].
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
