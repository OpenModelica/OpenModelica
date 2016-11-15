// name: loop4.mo
// keywords:
// status: incorrect
// cflags:   -d=newInst
//


model A
  constant Real a = b;
  constant Real b = c;
  constant Real c = d;
  constant Real d = e;
  constant Real e = c;
end A;

// Result:
// Failed to type cref c
// Failed to type cref e
// Failed to type cref d
// Failed to type cref c
// Failed to type cref b
// Error processing file: loop4.mo
// Error: Cyclically dependent constants or parameters found in scope : {d, c, e}.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
