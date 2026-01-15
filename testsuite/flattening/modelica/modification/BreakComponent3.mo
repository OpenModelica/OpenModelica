// name:     BreakComponent3
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
  M w;
end A;

model B
  extends A(break x, break z);
end B;

model C
  extends A(break z);
end C;

model BreakComponent3
  extends B;
  extends C;
end BreakComponent3;

// Result:
// class BreakComponent3
//   Real y.x;
//   Real w.x;
//   Real x.x;
// end BreakComponent3;
// endResult
