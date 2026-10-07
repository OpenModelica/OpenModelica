// name: StreamUnbalancedConnector
// keywords: stream connector unbalanced
// status: incorrect
//
// Checks that unbalanced stream connectors generate an error message.
//

connector S
  Real r;
  stream Real s;
  annotation(__OpenModelica_commandLineOptions="-d=-newInst");
end S;

// Result:
// Error processing file: StreamUnbalancedConnector.mo
// Warning: The old frontend (-d=-newInst) is deprecated and will be removed after OpenModelica 1.28.0 is released. Please report models that only work with the old frontend, see https://github.com/OpenModelica/OpenModelica/issues/17177.
// [flattening/modelica/streams/StreamUnbalancedConnector.mo:8:1-12:6:writable] Warning: Connector .S is not balanced: The number of potential variables (1) is not equal to the number of flow variables (0).
// [flattening/modelica/streams/StreamUnbalancedConnector.mo:8:1-12:6:writable] Error: Invalid stream connector .S: A stream connector must have exactly one flow variable, this connector has 0 flow variables.
// Error: Error occurred while flattening model S
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
