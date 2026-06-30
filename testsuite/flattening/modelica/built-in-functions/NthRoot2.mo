// name:     NthRoot2
// keywords: builtin
// status:   incorrect
//
// Test builtin function nthRoot.
//

model NthRoot2
  Real x;
equation
  x = nthRoot(-4, 2);
end NthRoot2;

// Result:
// Error processing file: NthRoot2.mo
// [flattening/modelica/built-in-functions/NthRoot2.mo:11:3-11:21:writable] Error: Invalid operation nthRoot(v = -4.0, n = 2), v must be non-negative when n is even.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
