// name: ListReductionDimError
// cflags: +g=MetaModelica -d=-newInst
// status: incorrect
// suite: metamodelica

class ListReductionDimError
  Real r[3];
equation
  r = {i for i in {-3,3}};
end ListReductionDimError;

// Result:
// Error processing file: ListReductionDimError.mo
// Warning: The old frontend (-d=-newInst) is deprecated and will be removed after OpenModelica 1.28.0 is released. Please report models that only work with the old frontend, see https://github.com/OpenModelica/OpenModelica/issues/17177.
// [metamodelica/meta/ListReductionDimError.mo:9:3-9:26:writable] Error: Type mismatch in equation {r[1], r[2], r[3]}={-3, 3} of type Real[3]=Integer[2].
// Error: Error occurred while flattening model ListReductionDimError
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
