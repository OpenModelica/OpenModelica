// name:     ImportUnqualified2
// keywords: unqualified import
// status:   correct
// cflags:   -d=newInst
//
// Checks that unqualified imports work.
//
// FAILREASON: Imported package constants are not instantiated.
//

package P
  constant Real x = 2;
end P;

model ImportUnqualified2
  import P.*;
  Real y = x;
end ImportUnqualified2;

// Result:
// Failed to type cref x
// Error processing file: ImportUnqualified2.mo
// Error: Internal error Instantiation of ImportUnqualified2 failed with no error message.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
