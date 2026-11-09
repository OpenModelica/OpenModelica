// status: incorrect
// Bug #2401

model InvalidPartialFunction
  Real x(start = function f1(x = 1));
end InvalidPartialFunction;

// Result:
// Error processing file: InvalidPartialFunction.mo
// Failed to parse file: InvalidPartialFunction.mo!
//
// [openmodelica/parser/InvalidPartialFunction.mo:5:18-5:36:writable] Error: Function partial application expressions are only allowed as inputs to functions.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
// Failed to parse file: InvalidPartialFunction.mo!
//
// Execution failed!
// endResult
