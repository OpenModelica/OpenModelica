// name:     InvalidSizeScalar
// keywords: size scalar
// status:   incorrect
//
// size of scalars is not allowed.
//

model InvalidSizeScalar
  Real r;
  Real s = size(r);
end InvalidSizeScalar;

// Result:
// Error processing file: InvalidSizeScalar.mo
// [flattening/modelica/built-in-functions/InvalidSizeScalar.mo:10:3-10:19:writable] Error: Type mismatch in binding 's = size(r)', expected array dimensions [], got [0].
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
