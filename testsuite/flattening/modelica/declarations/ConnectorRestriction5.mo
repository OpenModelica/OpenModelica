// name: ConnectorRestriction5
// keywords:
// status: incorrect
//

connector C
  Real e;
  flow Real f;
protected
  constant Integer n = 2;
end C;

model ConnectorRestriction5
  C c;
end ConnectorRestriction5;

// Result:
// Error processing file: ConnectorRestriction5.mo
// [flattening/modelica/declarations/ConnectorRestriction5.mo:10:3-10:25:writable] Error: Protected sections are not allowed in connector.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
