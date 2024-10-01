// name: ConnectorRestriction6
// keywords:
// status: incorrect
//

connector C
  Real e;
  flow Real f;
protected
  import Whatever;
end C;

model ConnectorRestriction6
  C c;
end ConnectorRestriction6;

// Result:
// Error processing file: ConnectorRestriction6.mo
// [flattening/modelica/declarations/ConnectorRestriction6.mo:10:3-10:18:writable] Error: Protected sections are not allowed in connector.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
