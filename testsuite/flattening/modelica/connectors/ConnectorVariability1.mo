// name: ConnectorVariability1
// keywords: connector
// status: incorrect
//
//

connector C
  input Real x = 1.0;
end C;

model ConnectorVariability1
  parameter C c;
end ConnectorVariability1;

// Result:
// Error processing file: ConnectorVariability1.mo
// [flattening/modelica/connectors/ConnectorVariability1.mo:12:3-12:16:writable] Error: Invalid variability parameter on connector 'c'.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
