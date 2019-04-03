// name: dim2.mo
// keywords:
// status: correct
// cflags:   -d=newInst
//
// FAILREASON: Dimensions not subscripted during expansion.
//


model N
  parameter Integer n;
  Real r[n];
end N;

model M
  N[2] n(n = {3,4});
equation
  n[1].r = {1,2,3};
  n[2].r = {4,5,6,7};
end M;

// Result:
// Unknown dimension in SCodeExpand.expandArray
// SCodeInst.instClass failed
// Error processing file: dim2.mo
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
