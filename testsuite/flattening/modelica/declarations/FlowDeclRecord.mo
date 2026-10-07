// name: FlowDeclRecord
// keywords: flow
// status: correct
//
// Tests the flow prefix on a record type
//

record FlowRecord
  Real r;
end FlowRecord;

class FlowDeclRecord
  flow FlowRecord fr;
equation
  fr.r = 1.0;
end FlowDeclRecord;

// Result:
// class FlowDeclRecord
//   Real fr.r;
// equation
//   fr.r = 1.0;
// end FlowDeclRecord;
// [flattening/modelica/declarations/FlowDeclRecord.mo:9:3-9:9:writable] Warning: Prefix 'flow' used outside connector declaration.
// [flattening/modelica/declarations/FlowDeclRecord.mo:13:3-13:21:writable] Warning: Prefix 'flow' used outside connector declaration.
// [flattening/modelica/declarations/FlowDeclRecord.mo:13:3-13:21:writable] Warning: Components are deprecated in class.
// [flattening/modelica/declarations/FlowDeclRecord.mo:15:3-15:13:writable] Warning: Equation sections are deprecated in class.
//
// endResult
