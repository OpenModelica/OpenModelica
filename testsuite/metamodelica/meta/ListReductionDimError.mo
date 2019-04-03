// name: ListReductionDimError
// cflags: +g=MetaModelica
// status: incorrect

class ListReductionDimError
  Real r[3];
equation
  r = {i for i in {-3,3}};
end ListReductionDimError;

// Result:
// Error processing file: ListReductionDimError.mo
// [metamodelica/meta/ListReductionDimError.mo:8:3-8:26:writable] Error: Type mismatch in equation {r[1], r[2], r[3]}={-3, 3} of type Real[3]=Integer[2].
// Error: Error occurred while flattening model ListReductionDimError
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
