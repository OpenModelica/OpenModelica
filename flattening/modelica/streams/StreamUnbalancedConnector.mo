// name: StreamUnbalancedConnector
// keywords: stream connector unbalanced
// status: incorrect
//
// Checks that unbalanced stream connectors generate an error message.
//

connector S
  Real r;
  stream Real s;
end S;

// Result:
// Error processing file: StreamUnbalancedConnector.mo
// [flattening/modelica/streams/StreamUnbalancedConnector.mo:8:1-11:6:writable] Warning: Connector .S is not balanced: The number of potential variables (1) is not equal to the number of flow variables (0).
// [flattening/modelica/streams/StreamUnbalancedConnector.mo:8:1-11:6:writable] Error: Invalid stream connector .S: A stream connector must have exactly one flow variable, this connector has 0 flow variables.
// Error: Error occurred while flattening model S
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
