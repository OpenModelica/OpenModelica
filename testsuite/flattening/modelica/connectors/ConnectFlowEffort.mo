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

class ConnectFlowEffort
  Connector1 c1;
  Connector2 c2;
equation
  connect(c1, c2);
end ConnectFlowEffort;

// Result:
// Error processing file: ConnectFlowEffort.mo
// [flattening/modelica/connectors/ConnectFlowEffort.mo:21:3-21:18:writable] Error: Cannot connect flow component c2.e to non-flow component c1.e.
// [flattening/modelica/connectors/ConnectFlowEffort.mo:21:3-21:18:writable] Error: The type of variables
// c1 type:
// connector Connector1
//   Real e;
// end Connector1; and
// c2 type:
// connector Connector2
//   flow Real e;
// end Connector2;
// are inconsistent in connect equations.
// Error: Error occurred while flattening model ConnectFlowEffort
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
