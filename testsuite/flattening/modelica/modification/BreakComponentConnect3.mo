// name:     BreakComponentConnect3
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

model BreakComponentConnect3
  extends B(break a1);
  C a1;
end BreakComponentConnect3;

// Result:
// class BreakComponentConnect3
//   Real a2.c.e;
//   Real a2.c.f;
//   Real a1.e;
//   Real a1.f;
// equation
//   a2.c.f = 0.0;
//   a1.f = 0.0;
// end BreakComponentConnect3;
// endResult
