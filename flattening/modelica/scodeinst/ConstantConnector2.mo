// name: ConstantConnector2
// keywords:
// status: correct
// cflags: -d=newInst
//

model ConstantConnector2
  connector C = constant Real;

  C c1, c2;
equation
  connect(c1, c2);
end ConstantConnector2;

// Result:
// class ConstantConnector2
// equation
//   assert(abs(c1 - c2) <= 0.0, "automatically generated from connect");
// end ConstantConnector2;
// endResult
