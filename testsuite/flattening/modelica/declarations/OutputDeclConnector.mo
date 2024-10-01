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

class OutputDeclConnector
  output OutputConnector oc;
equation
  oc.r = 1.0;
  annotation(__OpenModelica_commandLineOptions="-d=-newInst");
end OutputDeclConnector;

// Result:
// class OutputDeclConnector
//   output Real oc.r;
//   output Real oc.f;
// equation
//   oc.r = 1.0;
//   oc.f = 0.0;
// end OutputDeclConnector;
// endResult
