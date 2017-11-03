// name: ConnectDiffOrder1
// keywords:
// status: correct
// cflags: -d=newInst
//

connector C1
  Real e1;
  flow Real f1;
  flow Real f2;
  Real e2;
end C1;

connector C2
  flow Real f2;
  Real e2;
  flow Real f1;
  Real e1;
end C2;

model ConnectDiffOrder1
  C1 c1;
  C2 c2;
equation
  connect(c1, c2);
end ConnectDiffOrder1;

// Result:
// class ConnectDiffOrder1
//   Real c1.e1;
//   Real c1.f1;
//   Real c1.f2;
//   Real c1.e2;
//   Real c2.f2;
//   Real c2.e2;
//   Real c2.f1;
//   Real c2.e1;
// equation
//   c1.e1 = c2.e1;
//   c1.e2 = c2.e2;
//   (-c1.f1) + (-c2.f1) = 0.0;
//   (-c1.f2) + (-c2.f2) = 0.0;
//   c1.f1 = 0.0;
//   c1.f2 = 0.0;
//   c2.f2 = 0.0;
//   c2.f1 = 0.0;
// end ConnectDiffOrder1;
// endResult
