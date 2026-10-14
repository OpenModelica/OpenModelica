// name:     BreakComponentOuter1
// keywords: modification break
// status:   correct
//

model A
  Real x;
end A;

model B
  outer A a;
end B;

model BreakComponentOuter1
  extends B(break a);
end BreakComponentOuter1;

// Result:
// class BreakComponentOuter1
// end BreakComponentOuter1;
// endResult
