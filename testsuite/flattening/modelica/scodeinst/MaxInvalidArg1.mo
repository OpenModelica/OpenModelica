// name: MaxInvalidArg1
// keywords: max
// status: incorrect
//

model MaxInvalidArg1
  String s = max("str1", "str2");
end MaxInvalidArg1;

// Result:
// Error processing file: MaxInvalidArg1.mo
// [flattening/modelica/scodeinst/MaxInvalidArg1.mo:7:3-7:33:writable] Error: No matching function found for max("str1", "str2").
// Candidates are:
//   max(Real, Real) => Real
//   max(Integer, Integer) => Integer
//   max(Boolean, Boolean) => Boolean
//   max(enumeration(:), enumeration(:)) => enumeration(:)
//   max(Real[:, ...]) => Real
//   max(Integer[:, ...]) => Integer
//   max(Boolean[:, ...]) => Boolean
//   max(enumeration(:)[:, ...]) => enumeration(:)
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
