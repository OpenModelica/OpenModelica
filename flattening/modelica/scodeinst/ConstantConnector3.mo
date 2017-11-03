// name: ConstantConnector3
// keywords:
// status: correct
// cflags: -d=newInst
//

model ConstantConnector3
  connector C
    parameter Real x;
    Real e;
    flow Real f;
  end C;

  C c1, c2;
equation
  connect(c1, c2);
end ConstantConnector3;

// Result:
// class ConstantConnector3
//   parameter Real c1.x;
//   Real c1.e;
//   Real c1.f;
//   parameter Real c2.x;
//   Real c2.e;
//   Real c2.f;
// equation
//   c1.e = c2.e;
//   assert(abs(c1.x - c2.x) <= 0.0, "Connected constants/parameters must be equal");
//   (-c1.f) + (-c2.f) = 0.0;
//   c1.f = 0.0;
//   c2.f = 0.0;
// end ConstantConnector3;
// endResult
