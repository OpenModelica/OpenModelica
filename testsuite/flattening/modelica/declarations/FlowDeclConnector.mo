// name: FlowDeclConnector
// keywords: flow
// cflags: +std=2.x
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
end FlowDeclConnector;

// Result:
// class FlowDeclConnector
//   Real fc.r;
// equation
//   fc.r = 1.0;
// end FlowDeclConnector;
// endResult
