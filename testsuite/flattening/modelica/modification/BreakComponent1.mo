// name:     BreakComponent1
// keywords: modification break
// status:   correct
//

model M
  Real x;
end M;

model A
  M x;
  M y;
end A;

model BreakComponent1
  extends A(break x);
end BreakComponent1;

// Result:
// class BreakComponent1
//   Real y.x;
// end BreakComponent1;
// endResult
