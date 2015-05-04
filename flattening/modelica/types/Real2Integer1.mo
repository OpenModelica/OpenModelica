// name:     Real2Integer1
// keywords: type
// status:   incorrect
//
// No implicit conversion from 'Real' to 'Integer'. But integers are
// converted to reals in equations with real-expressions.
//

class Real2Integer1
  Real a = 5.6;
  Integer n = a;
end Real2Integer1;

// Result:
// Error processing file: Real2Integer1.mo
// [flattening/modelica/types/Real2Integer1.mo:11:3-11:16:writable] Error: Type mismatch in binding n = a, expected subtype of Integer, got type Real.
// Error: Error occurred while flattening model Real2Integer1
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
