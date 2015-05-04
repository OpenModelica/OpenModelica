// name: DiscreteDeclConnector
// keywords: discrete
// status: correct
//
// Tests the discrete prefix on a connector type
//

connector DiscreteConnector
  Real r;
  flow Real f;
end DiscreteConnector;

class DiscreteDeclConnector
  discrete DiscreteConnector dc;
equation
  dc.r = 1.0;
end DiscreteDeclConnector;

// Result:
// class DiscreteDeclConnector
//   discrete Real dc.r;
//   discrete Real dc.f;
// equation
//   dc.r = 1.0;
//   dc.f = 0.0;
// end DiscreteDeclConnector;
// endResult
