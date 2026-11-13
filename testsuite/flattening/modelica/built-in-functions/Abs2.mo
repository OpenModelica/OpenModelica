// name:     Abs2
// keywords: abs operator
// status:   incorrect
//
//  The abs operator
//


model Abs
  Boolean b;
equation
  b=abs(b);
end Abs;

// Result:
// Error processing file: Abs2.mo
// [flattening/modelica/built-in-functions/Abs2.mo:12:3-12:11:writable] Error: No matching function found for abs(/*Boolean*/ b).
// Candidates are:
//   abs(Integer v) => Integer
//   abs(Real v) => Real
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
