// name: OutputDeclConnector
// keywords: output
// status: correct
//
// Tests the output prefix on a connector type
//

connector OutputConnector
  Real r;
  flow Real f;
end OutputConnector;

model OutputDeclConnector
  output OutputConnector oc;
equation
  oc.r = 1.0;
end OutputDeclConnector;

// Result:
// class OutputDeclConnector
//   output Real oc.r;
//   output Real oc.f;
// equation
//   oc.f = 0.0;
//   oc.r = 1.0;
// end OutputDeclConnector;
// [flattening/modelica/declarations/OutputDeclConnector.mo:14:3-14:28:writable] Warning: Connector oc is not balanced: The number of potential variables (0) is not equal to the number of flow variables (1).
//
// endResult
