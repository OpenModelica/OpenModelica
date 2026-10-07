// name: ErrorInvalidComplexType
// cflags: +g=MetaModelica -d=-newInst
// status: incorrect
// suite: metamodelica
package ErrorInvalidComplexType

constant option<String> str = NONE();

end ErrorInvalidComplexType;

// Result:
// Error processing file: ErrorInvalidComplexType.mo
// Warning: The old frontend (-d=-newInst) is deprecated and will be removed after OpenModelica 1.28.0 is released. Please report models that only work with the old frontend, see https://github.com/OpenModelica/OpenModelica/issues/17177.
// [metamodelica/meta/ErrorInvalidComplexType.mo:7:1-7:37:writable] Error: Class option not found in scope ErrorInvalidComplexType.option.
// [metamodelica/meta/ErrorInvalidComplexType.mo:7:1-7:37:writable] Error: Invalid complex type name: option<String>
// Error: Error occurred while flattening model ErrorInvalidComplexType
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
