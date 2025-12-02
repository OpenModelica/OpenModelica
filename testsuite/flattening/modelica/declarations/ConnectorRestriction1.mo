// name: ConnectorRestriction1
// keywords:
// status: incorrect
//

connector C
  Real e;
  flow Real f;
equation
  e = f;
end C;

model ConnectorRestriction1
  C c;
end ConnectorRestriction1;

// Result:
// Error processing file: ConnectorRestriction1.mo
// [flattening/modelica/declarations/ConnectorRestriction1.mo:10:3-10:8:writable] Error: Equations are not allowed in connector.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
