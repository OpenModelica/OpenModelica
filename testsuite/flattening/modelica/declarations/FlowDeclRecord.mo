// name: FlowDeclRecord
// keywords: flow
// status: correct
//
// Tests the flow prefix on a record type
//

record FlowRecord
  Real r;
end FlowRecord;

model FlowDeclRecord
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
//
// endResult
