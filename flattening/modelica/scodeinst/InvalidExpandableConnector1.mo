// name: InvalidExpandableConnector1
// keywords:
// status: incorrect
// cflags: -d=newInst
//


expandable connector EC
end EC;

connector C
  Real x;
end C;

model InvalidExpandableConnector1
  EC ec;
  C c;
equation
  connect(ec, c);
end InvalidExpandableConnector1;

// Result:
// Error processing file: InvalidExpandableConnector1.mo
// [InvalidExpandableConnector1.mo:19:3-19:17:writable] Error: Cannot connect expandable connector ec with non-expandable connector c.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
