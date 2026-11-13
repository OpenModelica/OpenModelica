// name: InputDeclConnector
// keywords: input
// status: correct
//
// Tests the input prefix on a connector type
//

connector InputConnector
  Real r;
  flow Real f;
end InputConnector;

model InputDeclConnector
  input InputConnector ic;
equation
  ic.r = 1.0;
end InputDeclConnector;

// Result:
// class InputDeclConnector
//   input Real ic.r;
//   input Real ic.f;
// equation
//   ic.f = 0.0;
//   ic.r = 1.0;
// end InputDeclConnector;
// [flattening/modelica/declarations/InputDeclConnector.mo:14:3-14:26:writable] Warning: Connector ic is not balanced: The number of potential variables (0) is not equal to the number of flow variables (1).
//
// endResult
