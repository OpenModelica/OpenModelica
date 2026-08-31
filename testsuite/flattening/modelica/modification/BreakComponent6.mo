// name:     BreakComponent6
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
end A;

model B
  M x;
  M z;
end B;

model C
  extends A;
  extends B;
end C;

model BreakComponent6
  extends C(break x, break y);
end BreakComponent6;

// Result:
// class BreakComponent6
//   Real z.x;
// end BreakComponent6;
// endResult
