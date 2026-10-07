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
// [flattening/modelica/declarations/FlowDeclType.mo:9:3-9:24:writable] Warning: Prefix 'flow' used outside connector declaration.
// [flattening/modelica/declarations/FlowDeclType.mo:9:3-9:24:writable] Warning: Components are deprecated in class.
//
// endResult
