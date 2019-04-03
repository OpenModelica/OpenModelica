// name: InnerOuterExtends1
// keywords:
// status: correct
// cflags: -d=newInst
//

model A
  outer model M = B;
  extends M;
end A;

model B
  Real x;
end B;

model C
  Real x = 1.0;
end C;

model InnerOuterExtends1
  A a;
  inner model M = C;
end InnerOuterExtends1;

// Result:
// class InnerOuterExtends1
//   Real a.x = 1.0;
// end InnerOuterExtends1;
// endResult
