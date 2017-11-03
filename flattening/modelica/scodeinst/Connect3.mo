// name: Connect3
// keywords:
// status: correct
// cflags: -d=newInst
//

connector C
  Real e;
  flow Real f;
end C;

class C2 = C;

model Connect3
  C2 c1, c2;
equation
  connect(c1, c2);
end Connect3;

// Result:
// class Connect3
//   Real c1.e;
//   Real c1.f;
//   Real c2.e;
//   Real c2.f;
// equation
//   c1.e = c2.e;
//   (-c1.f) + (-c2.f) = 0.0;
//   c1.f = 0.0;
//   c2.f = 0.0;
// end Connect3;
// endResult
