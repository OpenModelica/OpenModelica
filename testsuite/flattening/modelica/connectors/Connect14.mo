// name: Connect14
// keywords:  connector, primitive types
// status: correct
//
// Test that all primitive types can be used in connectors.
//
connector BooleanSignal = Boolean;


connector StrangeConnector
  String s;
  BooleanSignal b;
  Integer n;
  Real x;
end StrangeConnector;

model Connect14
  StrangeConnector c1,c2;
  BooleanSignal b2;
equation
  connect(c1,c2);
  connect(c1.b,b2);
  annotation(__OpenModelica_commandLineOptions="+std=2.x");
end Connect14;
// Result:
// class Connect14
//   String c1.s;
//   Boolean c1.b;
//   Integer c1.n;
//   Real c1.x;
//   String c2.s;
//   Boolean c2.b;
//   Integer c2.n;
//   Real c2.x;
//   Boolean b2;
// equation
//   c1.b = b2;
//   c1.b = c2.b;
//   c1.n = c2.n;
//   c1.s = c2.s;
//   c1.x = c2.x;
// end Connect14;
// [flattening/modelica/connectors/Connect14.mo:18:3-18:25:writable] Warning: Connector c1 is not balanced: The number of potential variables (4) is not equal to the number of flow variables (0).
// [flattening/modelica/connectors/Connect14.mo:18:3-18:25:writable] Warning: Connector c2 is not balanced: The number of potential variables (4) is not equal to the number of flow variables (0).
// [flattening/modelica/connectors/Connect14.mo:19:3-19:19:writable] Warning: Connector b2 is not balanced: The number of potential variables (1) is not equal to the number of flow variables (0).
//
// endResult
