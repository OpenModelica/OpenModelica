// name:     BreakConnect1
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

model BreakConnect1
  extends A(break connect(c1, c2));
end BreakConnect1;

// Result:
// class BreakConnect1
//   Real c1.e;
//   Real c1.f;
//   Real c2.e;
//   Real c2.f;
// equation
//   c1.f = 0.0;
//   c2.f = 0.0;
// end BreakConnect1;
// endResult
