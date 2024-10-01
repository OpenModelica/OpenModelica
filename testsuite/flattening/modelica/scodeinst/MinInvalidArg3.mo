// name: MinInvalidArg3
// keywords: min
// status: incorrect
//

model MinInvalidArg3
  Real x = min(1, 2, 3);
end MinInvalidArg3;

// Result:
// Error processing file: MinInvalidArg3.mo
// [flattening/modelica/scodeinst/MinInvalidArg3.mo:7:3-7:24:writable] Error: No matching function found for min(1, 2, 3).
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
