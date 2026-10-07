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
  annotation(__OpenModelica_commandLineOptions="-d=-newInst");
end DiscreteDeclConnector;

// Result:
// class DiscreteDeclConnector
//   discrete Real dc.r;
//   discrete Real dc.f;
// equation
//   dc.r = 1.0;
//   dc.f = 0.0;
// end DiscreteDeclConnector;
// Warning: The old frontend (-d=-newInst) is deprecated and will be removed after OpenModelica 1.28.0 is released. Please report models that only work with the old frontend, see https://github.com/OpenModelica/OpenModelica/issues/17177.
//
// endResult
