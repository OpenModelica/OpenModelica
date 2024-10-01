// name: ConnectorRestriction7
// keywords:
// status: incorrect
//

connector C1
  Real e;
  flow Real f;
end C1;

connector C2
protected
  extends C1;
end C2;

model ConnectorRestriction7
  C2 c;
end ConnectorRestriction7;

// Result:
// Error processing file: ConnectorRestriction7.mo
// [flattening/modelica/declarations/ConnectorRestriction7.mo:13:3-13:13:writable] Error: Protected sections are not allowed in connector.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
