// name: FlowDeclConnector
// keywords: flow
// status: correct
//
// Tests the flow prefix on a connector type
//

connector FlowConnector
  Real r;
end FlowConnector;

class FlowDeclConnector
  flow FlowConnector fc;
equation
  fc.r = 1.0;
  annotation(__OpenModelica_commandLineOptions="+std=2.x");
end FlowDeclConnector;

// Result:
// class FlowDeclConnector
//   Real fc.r;
// equation
//   fc.r = 0.0;
//   fc.r = 1.0;
// end FlowDeclConnector;
// [flattening/modelica/declarations/FlowDeclConnector.mo:13:3-13:24:writable] Warning: Components are deprecated in class.
// [flattening/modelica/declarations/FlowDeclConnector.mo:15:3-15:13:writable] Warning: Equation sections are deprecated in class.
// [flattening/modelica/declarations/FlowDeclConnector.mo:13:3-13:24:writable] Warning: Connector fc is not balanced: The number of potential variables (0) is not equal to the number of flow variables (1).
//
// endResult
