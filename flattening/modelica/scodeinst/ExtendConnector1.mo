// name: ExtendConnector1
// keywords:
// status: correct
// cflags: -d=newInst
//

partial connector C1
  Real e;
  flow Real f;
end C1;

connector C2
  extends C1;
  stream Real s;
end C2;

model ExtendConnector1
  C2 c1, c2;
equation
  connect(c1, c2);
end ExtendConnector1;

// Result:
// class ExtendConnector1
//   Real c1.e;
//   Real c1.f;
//   Real c1.s;
//   Real c2.e;
//   Real c2.f;
//   Real c2.s;
// equation
//   c1.e = c2.e;
//   (-c1.f) + (-c2.f) = 0.0;
//   c1.s = c2.s;
//   c2.s = c1.s;
//   c1.f = 0.0;
//   c2.f = 0.0;
// end ExtendConnector1;
// endResult
