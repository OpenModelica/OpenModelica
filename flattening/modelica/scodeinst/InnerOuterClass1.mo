// name: InnerOuterClass1
// keywords:
// status: correct
// cflags: -d=newInst
//

model A
  Real x;
end A;

model B
  Real x;
  Real y;
end B;

model C
  outer model M = A;
  M m;
end C;

model D
  inner model M = B;
  C c;
end D;

// Result:
// class D
//   Real c.m.x;
//   Real c.m.y;
// end D;
// endResult
