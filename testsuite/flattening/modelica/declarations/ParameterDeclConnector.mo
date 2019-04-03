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
end ParameterDeclConnector;

// Result:
// class ParameterDeclConnector
//   parameter Real pc.r;
//   parameter Real pc.f;
// equation
//   pc.r = 1.0;
//   pc.f = 0.0;
// end ParameterDeclConnector;
// endResult
