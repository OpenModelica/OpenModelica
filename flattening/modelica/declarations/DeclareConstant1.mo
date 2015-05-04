// name:     DeclareConstant1
// keywords: declaration,equation
// status:   incorrect
//
// A constant requires a declaration equation.
// A normal equation from which we can compute
// the constant is not sufficient.

class DeclareConstant1
  constant String s;
equation
  s = "value";
end DeclareConstant1;
