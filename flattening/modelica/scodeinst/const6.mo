// name: const6.mo
// keywords:
// status: incorrect
// cflags:   -d=newInst
//
// FAILREASON: Variability not yet propagated.
//


model M
  constant Integer i = 3;
  constant Integer j = x;
  parameter Integer x = i;
end M;

// Result:
//
// EXPANDED FORM:
//
// class M
//   parameter Integer x = 3;
// end M;
//
//
// Found 0 components and 1 parameters.
// Error processing file: const6.mo
// [const6.mo:9:3-9:25:writable] Error: Component j of variability CONST has binding x of higher variability PARAM.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
