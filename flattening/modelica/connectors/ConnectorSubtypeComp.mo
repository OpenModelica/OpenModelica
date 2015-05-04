// name:     ConnectorSubtypeComp
// keywords: connect, connector, #2741
// status:   correct
//
// Checks that subtype components are counted correctly in connectors.
//

type MyReal
  extends Real;
end MyReal;

type R = MyReal;

connector C
  R r;
  flow Real f;
end C;

model ConnectorSubtypeComp
  C c;
end ConnectorSubtypeComp;

// Result:
// class ConnectorSubtypeComp
//   Real c.r;
//   Real c.f;
// equation
//   c.f = 0.0;
// end ConnectorSubtypeComp;
// endResult
