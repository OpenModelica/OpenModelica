// name:     DerConstant2
// keywords: derivative
// status:   incorrect
//
// The argument to der must be a subtype of Real, even when constant.
//

class DerConstant2
  constant Integer pa = 1;
  Real a = der(pa);
end DerConstant2;

// Result:
// Error processing file: DerConstant2.mo
// [flattening/modelica/built-in-functions/DerConstant2.mo:10:3-10:19:writable] Error: Argument 'pa' to der has illegal type Integer, must be a subtype of Real.
// Error: Error occurred while flattening model DerConstant2
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
