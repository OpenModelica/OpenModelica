// name:     BreakComponentConnect1
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

model BreakComponentConnect1
  extends A(break c1);
end BreakComponentConnect1;

// Result:
// class BreakComponentConnect1
//   Real c2.e;
//   Real c2.f;
// equation
//   c2.f = 0.0;
// end BreakComponentConnect1;
// endResult
