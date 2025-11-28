// name: ConnectorVariability2
// keywords: connector
// status: correct
//
//

model ConnectorVariability2
  connector RealInput = input Real;
  parameter RealInput ri = 0;
end ConnectorVariability2;

// Result:
// class ConnectorVariability2
//   parameter input Real ri = 0.0;
// end ConnectorVariability2;
// endResult
