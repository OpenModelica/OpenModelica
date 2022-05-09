// name: MaxInvalidArg3
// keywords: max
// status: incorrect
// cflags: -d=newInst
//

model MaxInvalidArg3
  Real x = max(1, 2, 3);
end MaxInvalidArg3;

// Result:
// Error processing file: MaxInvalidArg3.mo
// [flattening/modelica/scodeinst/MaxInvalidArg3.mo:8:3-8:24:writable] Error: No matching function found for max(1, 2, 3).
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
