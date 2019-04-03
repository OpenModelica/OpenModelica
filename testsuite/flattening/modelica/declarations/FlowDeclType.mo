// name: FlowDeclType
// keywords: flow
// status: correct
//
// Tests the flow prefix on a regular type
//

class FlowDeclType
  flow Real rFlow = 1.0;
end FlowDeclType;

// Result:
// class FlowDeclType
//   Real rFlow = 1.0;
// end FlowDeclType;
// endResult
