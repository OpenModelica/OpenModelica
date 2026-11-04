// name:     ConnectFlowEffort
// keywords: connect,modification
// status:   incorrect
//
// Flow and effort variables may not be connected.
//

connector Connector1
  Real e;
end Connector1;

connector Connector2
  flow Real e;
end Connector2;

model ConnectFlowEffort
  Connector1 c1;
  Connector2 c2;
equation
  connect(c1, c2);
  annotation(__OpenModelica_commandLineOptions="+std=2.x");
end ConnectFlowEffort;

// Result:
// Error processing file: ConnectFlowEffort.mo
// [flattening/modelica/connectors/ConnectFlowEffort.mo:17:3-17:16:writable] Warning: Connector c1 is not balanced: The number of potential variables (1) is not equal to the number of flow variables (0).
// [flattening/modelica/connectors/ConnectFlowEffort.mo:18:3-18:16:writable] Warning: Connector c2 is not balanced: The number of potential variables (0) is not equal to the number of flow variables (1).
// [flattening/modelica/connectors/ConnectFlowEffort.mo:20:3-20:18:writable] Error: The connectors in connect(c1, c2) are not type compatible.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
