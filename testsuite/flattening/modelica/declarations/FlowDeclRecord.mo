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
  annotation(__OpenModelica_commandLineOptions="-d=-newInst");
end FlowDeclRecord;

// Result:
// function FlowRecord "Automatically generated record constructor for FlowRecord"
//   input Real r;
//   output FlowRecord res;
// end FlowRecord;
//
// class FlowDeclRecord
//   Real fr.r;
// equation
//   fr.r = 1.0;
// end FlowDeclRecord;
// endResult
