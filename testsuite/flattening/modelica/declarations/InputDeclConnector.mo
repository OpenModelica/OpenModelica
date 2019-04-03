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

class InputDeclConnector
  input InputConnector ic;
equation
  ic.r = 1.0;
end InputDeclConnector;

// Result:
// class InputDeclConnector
//   input Real ic.r;
//   input Real ic.f;
// equation
//   ic.r = 1.0;
//   ic.f = 0.0;
// end InputDeclConnector;
// endResult
