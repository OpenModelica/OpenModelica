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

class ConnectFlowEffort2
  Connector1 c1;
  Connector2 c2;
equation
  connect(c2, c1);
  annotation(__OpenModelica_commandLineOptions="+std=2.x -d=-newInst");
end ConnectFlowEffort2;

// Result:
// Error processing file: ConnectFlowEffort2.mo
// Warning: The old frontend (-d=-newInst) is deprecated and will be removed after OpenModelica 1.28.0 is released. Please report models that only work with the old frontend, see https://github.com/OpenModelica/OpenModelica/issues/17177.
// [flattening/modelica/connectors/ConnectFlowEffort2.mo:20:3-20:18:writable] Error: Cannot connect flow component c2.e to non-flow component c1.e.
// [flattening/modelica/connectors/ConnectFlowEffort2.mo:20:3-20:18:writable] Error: The type of variables
// c2 type:
// connector Connector2
//   flow Real e;
// end Connector2; and
// c1 type:
// connector Connector1
//   Real e;
// end Connector1;
// are inconsistent in connect equations.
// Error: Error occurred while flattening model ConnectFlowEffort2
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
