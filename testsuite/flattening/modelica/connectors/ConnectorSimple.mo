// name: ConnectorSimple
// keywords: connector
// status: correct
// cflags: -d=-newInst
//
// Tests simple declaration and instantiation of a connector
//

connector SimpleConnector
end SimpleConnector;

model ConnectorSimple
  SimpleConnector sc;
end ConnectorSimple;

// Result:
// class ConnectorSimple
// end ConnectorSimple;
// endResult
