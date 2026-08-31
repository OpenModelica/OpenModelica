// name:     BreakComponentMod3
// keywords: modification break
// status:   correct
//

model M
  Real x;
end M;

model A
  M x;
end A;

model B
  extends A(break x);
  Integer x;
end B;

model BreakComponentMod3
  extends B(x = 1);
end BreakComponentMod3;

// Result:
// class BreakComponentMod3
//   Integer x = 1;
// end BreakComponentMod3;
// endResult
