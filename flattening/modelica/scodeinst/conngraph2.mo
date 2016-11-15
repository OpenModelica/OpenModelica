// name: conngraph2.mo
// keywords:
// status: correct
// cflags:   -d=newInst
//
// FAILREASON: Overconstrained types not yet recognized as such.
//

connector RealInput = input Real;

connector C
  RealInput ri;
end C;

model M
  C c1;
equation
  Connections.root(c1.ri);
end M;

// Result:
// Error processing file: conngraph2.mo
// [conngraph2.mo:17:3-17:26:writable] Error: The argument of Connections.root must be an overdetermined type or record.
// Error: Error occurred while flattening model M
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
