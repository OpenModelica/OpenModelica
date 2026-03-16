// name:     BreakComponent2
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

model BreakComponent2
  extends A(break x);
  Integer x;
end BreakComponent2;

// Result:
// class BreakComponent2
//   Real y.x;
//   Integer x;
// end BreakComponent2;
// endResult
