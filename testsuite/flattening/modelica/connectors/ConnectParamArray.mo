// name:     ConnectParamArray
// keywords: connect parameter array
// status:   correct
//
// Tests that asserts are generated for parameters arrays in connectors.
//

connector C
  parameter Real e[3];
end C;

model ConnectParamArray
  C c1, c2;
equation
  connect(c1, c2);
end ConnectParamArray;

// Result:
// class ConnectParamArray
//   parameter Real c1.e[1];
//   parameter Real c1.e[2];
//   parameter Real c1.e[3];
//   parameter Real c2.e[1];
//   parameter Real c2.e[2];
//   parameter Real c2.e[3];
// equation
//   assert(c1.e[1] == c2.e[1], "automatically generated from connect");
//   assert(c1.e[2] == c2.e[2], "automatically generated from connect");
//   assert(c1.e[3] == c2.e[3], "automatically generated from connect");
// end ConnectParamArray;
// endResult
