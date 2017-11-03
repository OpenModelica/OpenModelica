// name: ConnectDiffOrder2
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

connector C3
  C1 c1;
  C2 c2;
end C3;

connector C4
  C2 c2;
  C1 c1;
end C4;

model ConnectDiffOrder2
  C3 c3;
  C4 c4;
equation
  connect(c3, c4);
end ConnectDiffOrder2;

// Result:
// class ConnectDiffOrder2
//   Real c3.c1.e1;
//   Real c3.c1.f1;
//   Real c3.c1.f2;
//   Real c3.c1.e2;
//   Real c3.c2.f2;
//   Real c3.c2.e2;
//   Real c3.c2.f1;
//   Real c3.c2.e1;
//   Real c4.c2.f2;
//   Real c4.c2.e2;
//   Real c4.c2.f1;
//   Real c4.c2.e1;
//   Real c4.c1.e1;
//   Real c4.c1.f1;
//   Real c4.c1.f2;
//   Real c4.c1.e2;
// equation
//   c3.c1.e1 = c4.c1.e1;
//   c3.c1.e2 = c4.c1.e2;
//   (-c3.c1.f1) + (-c4.c1.f1) = 0.0;
//   (-c3.c1.f2) + (-c4.c1.f2) = 0.0;
//   c3.c2.e1 = c4.c2.e1;
//   c3.c2.e2 = c4.c2.e2;
//   (-c3.c2.f1) + (-c4.c2.f1) = 0.0;
//   (-c3.c2.f2) + (-c4.c2.f2) = 0.0;
//   c3.c1.f1 = 0.0;
//   c3.c1.f2 = 0.0;
//   c3.c2.f2 = 0.0;
//   c3.c2.f1 = 0.0;
//   c4.c2.f2 = 0.0;
//   c4.c2.f1 = 0.0;
//   c4.c1.f1 = 0.0;
//   c4.c1.f2 = 0.0;
// end ConnectDiffOrder2;
// endResult
