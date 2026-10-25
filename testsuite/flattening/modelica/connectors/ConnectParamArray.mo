// name:     ConnectParamArray
// keywords: connect parameter array
// status:   correct
//
// Tests that asserts are generated for parameters arrays in connectors.
//

connector C
  parameter Real e[3](each fixed = false);
end C;

model ConnectParamArray
  C c1, c2;
equation
  connect(c1, c2);
end ConnectParamArray;

// Result:
// class ConnectParamArray
//   parameter Real c1.e[1](fixed = false);
//   parameter Real c1.e[2](fixed = false);
//   parameter Real c1.e[3](fixed = false);
//   parameter Real c2.e[1](fixed = false);
//   parameter Real c2.e[2](fixed = false);
//   parameter Real c2.e[3](fixed = false);
// equation
//   assert(abs(c1.e[1] - c2.e[1]) <= 0.0, "Connected constants/parameters must be equal");
//   assert(abs(c1.e[2] - c2.e[2]) <= 0.0, "Connected constants/parameters must be equal");
//   assert(abs(c1.e[3] - c2.e[3]) <= 0.0, "Connected constants/parameters must be equal");
// end ConnectParamArray;
// endResult
