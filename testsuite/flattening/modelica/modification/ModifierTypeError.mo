// name: ModifierTypeError
// keywords: abs
// status: incorrect
// cflags: -d=-newInst
//
// Tests that type errors are caught.
//

package X
  constant Integer x = 1.0;
end X;

model A
   Integer k = X.x;
end A;

// Result:
// Error processing file: ModifierTypeError.mo
// [flattening/modelica/modification/ModifierTypeError.mo:10:3-10:27:writable] Error: Type mismatch in binding x = 1.0, expected subtype of Integer, got type Real.
// [flattening/modelica/modification/ModifierTypeError.mo:14:4-14:19:writable] Error: Variable X.x not found in scope A.
// Error: Error occurred while flattening model A
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
