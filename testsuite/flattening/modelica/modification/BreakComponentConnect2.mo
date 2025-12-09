// name:     BreakComponentConnect2
// keywords: modification break
// status:   correct
//

connector C
  Real e;
  flow Real f;
end C;

model A
  C c;
end A;

model B
  A a1, a2;
equation
  connect(a1.c, a2.c);
end B;

model BreakComponentConnect2
  extends B(break a1);
end BreakComponentConnect2;

// Result:
// class BreakComponentConnect2
//   Real a2.c.e;
//   Real a2.c.f;
// equation
//   a2.c.f = 0.0;
// end BreakComponentConnect2;
// endResult
