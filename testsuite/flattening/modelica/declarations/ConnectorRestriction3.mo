// name: ConnectorRestriction3
// keywords:
// status: incorrect
//

connector C
  Real e;
  flow Real f;
initial algorithm
  e := f;
end C;

model ConnectorRestriction3
  C c;
end ConnectorRestriction3;

// Result:
// Error processing file: ConnectorRestriction3.mo
// [flattening/modelica/declarations/ConnectorRestriction3.mo:10:3-10:9:writable] Error: Algorithm sections are not allowed in connector.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
