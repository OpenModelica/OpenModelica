// name: Connect2
// keywords:
// status: correct
// cflags: -d=newInst
//

connector C
  Real e;
  flow Real f;
end C;

model Connect2
  C c1, c2;
equation
  connect(c1, c2);
end Connect2;

// Result:
// class Connect2
//   Real c1.e;
//   Real c1.f;
//   Real c2.e;
//   Real c2.f;
// equation
//   c1.e = c2.e;
//   (-c1.f) + (-c2.f) = 0.0;
//   c1.f = 0.0;
//   c2.f = 0.0;
// end Connect2;
// endResult
