// name:     NthRoot3
// keywords: builtin
// status:   incorrect
//
// Test builtin function nthRoot.
//

model NthRoot3
  Real x;
equation
  x = nthRoot(4, -2);
end NthRoot3;

// Result:
// Error processing file: NthRoot3.mo
// [flattening/modelica/built-in-functions/NthRoot3.mo:11:3-11:21:writable] Error: Invalid operation nthRoot(v = 4.0, n = -2), n must be a positive integer.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
