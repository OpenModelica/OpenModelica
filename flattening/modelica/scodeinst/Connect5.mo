// name: Connect5
// keywords:
// status: correct
// cflags: -d=newInst
//

connector C
  Real e;
  flow Real f;
end C;

model A
  C c1(e(start = 1.0));
end A;

model Connect5
  A a;
  C c2;
equation
  connect(a.c1, c2);
end Connect5;

// Result:
// class Connect5
//   Real a.c1.e(start = 1.0);
//   Real a.c1.f;
//   Real c2.e;
//   Real c2.f;
// equation
//   a.c1.e = c2.e;
//   a.c1.f + (-c2.f) = 0.0;
//   c2.f = 0.0;
// end Connect5;
// endResult
