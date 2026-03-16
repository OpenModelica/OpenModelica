// name:     BreakComponentMod1
// keywords: modification break
// status:   correct
//

model M
  Real x;
end M;

model A
  M m;
end A;

model B
  extends A(m(x = 1));
end B;

model BreakComponentMod1
  extends A(break m);
end BreakComponentMod1;

// Result:
// class BreakComponentMod1
// end BreakComponentMod1;
// endResult
