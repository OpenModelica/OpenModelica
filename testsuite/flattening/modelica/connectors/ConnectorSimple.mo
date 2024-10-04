// name: ConnectorSimple
// keywords: connector
// status: correct
//
// Tests simple declaration and instantiation of a connector
//

connector SimpleConnector
end SimpleConnector;

model ConnectorSimple
  SimpleConnector sc;
  annotation(__OpenModelica_commandLineOptions="-d=-newInst");
end ConnectorSimple;

// Result:
// class ConnectorSimple
// end ConnectorSimple;
// endResult
