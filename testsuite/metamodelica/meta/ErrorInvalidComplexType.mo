// name: ErrorInvalidComplexType
// cflags: +g=MetaModelica
// status: incorrect
package ErrorInvalidComplexType

constant option<String> str = NONE();

end ErrorInvalidComplexType;

// Result:
// Error processing file: ErrorInvalidComplexType.mo
// [metamodelica/meta/ErrorInvalidComplexType.mo:6:1-6:37:writable] Error: Class option not found in scope ErrorInvalidComplexType.option.
// [metamodelica/meta/ErrorInvalidComplexType.mo:6:1-6:37:writable] Error: Invalid complex type name: option<String>
// Error: Error occurred while flattening model ErrorInvalidComplexType
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
