// name: ConnectorRestriction2
// keywords:
// status: incorrect
// cflags: -d=newInst
//

connector C
  Real e;
  flow Real f;
algorithm
  e := f;
end C;

model ConnectorRestriction2
  C c;
end ConnectorRestriction2;

// Result:
// Error processing file: ConnectorRestriction2.mo
// [flattening/modelica/declarations/ConnectorRestriction2.mo:11:3-11:9:writable] Error: Algorithm sections are not allowed in connector.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
