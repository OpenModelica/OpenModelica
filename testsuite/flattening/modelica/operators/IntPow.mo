// name: IntPow
// keywords: integer, power
// status: incorrect
// cflags: -d=-newInst
//
// tests Integer powers
//

model IntPow
  constant Integer i = 8 ^ 3;
end IntPow;

// Result:
// Error processing file: IntPow.mo
// [flattening/modelica/operators/IntPow.mo:10:3-10:29:writable] Error: Type mismatch in binding i = 512.0, expected subtype of Integer, got type Real.
// Error: Error occurred while flattening model IntPow
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
