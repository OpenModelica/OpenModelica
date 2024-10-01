// name: MinInvalidArg1
// keywords: min
// status: incorrect
//

model MinInvalidArg1
  String s = min("str1", "str2");
end MinInvalidArg1;

// Result:
// Error processing file: MinInvalidArg1.mo
// [flattening/modelica/scodeinst/MinInvalidArg1.mo:7:3-7:33:writable] Error: No matching function found for min("str1", "str2").
// Candidates are:
//   min(Real, Real) => Real
//   min(Integer, Integer) => Integer
//   min(Boolean, Boolean) => Boolean
//   min(enumeration(:), enumeration(:)) => enumeration(:)
//   min(Real[:, ...]) => Real
//   min(Integer[:, ...]) => Integer
//   min(Boolean[:, ...]) => Boolean
//   min(enumeration(:)[:, ...]) => enumeration(:)
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
