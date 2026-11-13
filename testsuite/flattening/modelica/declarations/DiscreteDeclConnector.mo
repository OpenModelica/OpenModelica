// name: DiscreteDeclConnector
// keywords: discrete
// status: correct
//
// Tests the discrete prefix on a connector type
//

connector DiscreteConnector
  output Real r;
end DiscreteConnector;

model DiscreteDeclConnector
  discrete DiscreteConnector dc;
equation
  when initial() then
    dc.r = 1.0;
  end when;
end DiscreteDeclConnector;

// Result:
// class DiscreteDeclConnector
//   discrete output Real dc.r;
// equation
//   when initial() then
//     dc.r = 1.0;
//   end when;
// end DiscreteDeclConnector;
// endResult
