// name:     BreakConnect3
// keywords: modification break
// status:   correct
//

connector C
  Real e;
  flow Real f;
end C;

model A
  C c1, c2;
equation
  connect(c1, c2);
end A;

model B
  C c3, c4;
equation
  connect(c3, c4);
end B;

model D
  extends A(break connect(c1, c2));
  extends B;
end D;

model BreakConnect3
  extends D(break connect(c3, c4));
end BreakConnect3;

// Result:
// class BreakConnect3
//   Real c1.e;
//   Real c1.f;
//   Real c2.e;
//   Real c2.f;
//   Real c3.e;
//   Real c3.f;
//   Real c4.e;
//   Real c4.f;
// equation
//   c1.f = 0.0;
//   c2.f = 0.0;
//   c3.f = 0.0;
//   c4.f = 0.0;
// end BreakConnect3;
// endResult
