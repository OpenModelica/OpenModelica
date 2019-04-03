// name:     ConnectFlowEffort
// keywords: connect,modification
// cflags: +std=2.x
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
end ConnectFlowEffort2;

// Result:
// Error processing file: ConnectFlowEffort2.mo
// [flattening/modelica/connectors/ConnectFlowEffort2.mo:21:3-21:18:writable] Error: Cannot connect flow component c2.e to non-flow component c1.e.
// [flattening/modelica/connectors/ConnectFlowEffort2.mo:21:3-21:18:writable] Error: The type of variables
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
