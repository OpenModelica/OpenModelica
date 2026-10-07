// name: ConstantDeclConnector
// keywords: constant
// status: correct
//
// Tests the constant prefix used on a connector
//

connector ConstantConnector
  Real r;
  flow Real f;
end ConstantConnector;

model ConstantDeclConnector
  constant ConstantConnector cc(r = 2.0);
  annotation(__OpenModelica_commandLineOptions="-d=-newInst");
end ConstantDeclConnector;

// Result:
// class ConstantDeclConnector
//   constant Real cc.r = 2.0;
//   constant Real cc.f;
// equation
//   cc.f = 0.0;
// end ConstantDeclConnector;
// Warning: The old frontend (-d=-newInst) is deprecated and will be removed after OpenModelica 1.28.0 is released. Please report models that only work with the old frontend, see https://github.com/OpenModelica/OpenModelica/issues/17177.
//
// endResult
