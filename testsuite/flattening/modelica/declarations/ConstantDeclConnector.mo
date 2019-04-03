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
end ConstantDeclConnector;

// Result:
// class ConstantDeclConnector
//   constant Real cc.r = 2.0;
//   constant Real cc.f;
// equation
//   cc.f = 0.0;
// end ConstantDeclConnector;
// endResult
