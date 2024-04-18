// name: ConstantConnector1
// keywords:
// status: correct
// cflags: -d=newInst
//

model ConstantConnector1
  connector C = parameter Real;

  C c1 = 0, c2 = 0;
equation
  connect(c1, c2);
end ConstantConnector1;

// Result:
// class ConstantConnector1
//   parameter Real c1 = 0.0;
//   parameter Real c2 = 0.0;
// equation
//   assert(abs(c1 - c2) <= 0.0, "Connected constants/parameters must be equal");
// end ConstantConnector1;
// endResult
