// name:     BreakComponent4
// keywords: modification break
// status:   correct
//

model M
  Real x;
end M;

model A
  M x;
  M y;
  M z;
  M w;
end A;

model B
  extends A(break x);
end B;

model C
  extends A;
end C;

model BreakComponent4
  B b;
  C c;
end BreakComponent4;

// Result:
// class BreakComponent4
//   Real b.y.x;
//   Real b.z.x;
//   Real b.w.x;
//   Real c.x.x;
//   Real c.y.x;
//   Real c.z.x;
//   Real c.w.x;
// end BreakComponent4;
// endResult
