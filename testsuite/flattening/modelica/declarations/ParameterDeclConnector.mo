// name: ParameterDeclConnector
// keywords: parameter
// status: correct
//
// Tests the parameter prefix on a connector type
//

connector ParameterConnector
  Real r;
  flow Real f;
end ParameterConnector;

class ParameterDeclConnector
  parameter ParameterConnector pc;
equation
  pc.r = 1.0;
  annotation(__OpenModelica_commandLineOptions="-d=-newInst");
end ParameterDeclConnector;

// Result:
// class ParameterDeclConnector
//   parameter Real pc.r;
//   parameter Real pc.f;
// equation
//   pc.r = 1.0;
//   pc.f = 0.0;
// end ParameterDeclConnector;
// Warning: The old frontend (-d=-newInst) is deprecated and will be removed after OpenModelica 1.28.0 is released. Please report models that only work with the old frontend, see https://github.com/OpenModelica/OpenModelica/issues/17177.
//
// endResult
