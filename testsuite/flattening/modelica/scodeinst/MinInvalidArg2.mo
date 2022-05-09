// name: MinInvalidArg2
// keywords: min
// status: incorrect
// cflags: -d=newInst
//

model MinInvalidArg2
  String s = min({"str1", "str2"});
end MinInvalidArg2;

// Result:
// Error processing file: MinInvalidArg2.mo
// [flattening/modelica/scodeinst/MinInvalidArg2.mo:8:3-8:35:writable] Error: No matching function found for min({"str1", "str2"}).
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
