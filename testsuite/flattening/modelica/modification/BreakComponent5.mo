// name:     BreakComponent5
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

model B
  M z;
  M w;
end B;

model C
  extends A;
  extends B;
end C;

model BreakComponent5
  extends C(break y, break z);
end BreakComponent5;

// Result:
// class BreakComponent5
//   Real x.x;
//   Real w.x;
// end BreakComponent5;
// endResult
