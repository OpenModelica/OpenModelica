// name:     BreakConnect4
// keywords: modification break
// status:   correct
//

connector C
  Real e;
  flow Real f;
end C;

model A
  C c1[3], c2[3];
equation
  for i in 1:2 loop
    connect(c1[i], c2[i]);
  end for;

  connect(c1[3], c2[3]);
end A;

model BreakConnect4
  extends A(break connect(c1[i], c2[i]));
end BreakConnect4;

// Result:
// class BreakConnect4
//   Real c1[1].e;
//   Real c1[1].f;
//   Real c1[2].e;
//   Real c1[2].f;
//   Real c1[3].e;
//   Real c1[3].f;
//   Real c2[1].e;
//   Real c2[1].f;
//   Real c2[2].e;
//   Real c2[2].f;
//   Real c2[3].e;
//   Real c2[3].f;
// equation
//   c1[3].e = c2[3].e;
//   -(c1[3].f + c2[3].f) = 0.0;
//   c1[1].f = 0.0;
//   c1[2].f = 0.0;
//   c1[3].f = 0.0;
//   c2[1].f = 0.0;
//   c2[2].f = 0.0;
//   c2[3].f = 0.0;
// end BreakConnect4;
// endResult
