// name: loop1.mo
// keywords:
// status: correct
// cflags:   -d=newInst
//
// FAILREASON: Not good enough error message.
//


model A
  constant Integer b = a;
  constant Integer a = i;
  constant Integer i = j;
  constant Integer x[i];
  constant Integer j = size(x, 1);
end A;

// Result:
// Failed to type cref i
// Failed to type cref j
// Failed to type cref i
// Failed to type cref a
// SCodeInst.instClass failed
// Error processing file: loop1.mo
// Error: Internal error Found cyclic dependencies, but failed to show error.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
