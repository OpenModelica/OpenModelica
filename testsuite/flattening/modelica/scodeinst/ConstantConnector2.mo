// name: ConstantConnector2
// keywords:
// status: correct
// cflags: -d=newInst
//

model ConstantConnector2
  connector C = constant Real;

  C c1 = 1, c2 = 2;
equation
  connect(c1, c2);
end ConstantConnector2;

// Result:
// class ConstantConnector2
//   constant Real c1 = 1.0;
//   constant Real c2 = 2.0;
// equation
//   assert(false, "Connected constants/parameters must be equal");
// end ConstantConnector2;
// endResult
