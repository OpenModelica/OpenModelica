// name: conn9.mo
// keywords:
// status: correct
// cflags:   -d=newInst
//

connector C
  Real e;
  Real f;
  Real s;
end C;

model A
  flow C c;
end A;

// Result:
// class A
//   Real c.e;
//   Real c.f;
//   Real c.s;
// equation
//   c.e = 0.0;
//   c.f = 0.0;
//   c.s = 0.0;
// end A;
// endResult
