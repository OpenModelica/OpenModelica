// name: InnerOuterPartialOuter1
// keywords:
// status: correct
// cflags: -d=newInst
//

partial model A
end A;

model B
  extends A;
  Real x;
end B;

model C
  outer A a;
end C;

model InnerOuterPartialOuter1
  C c;
  inner B a;
end InnerOuterPartialOuter1;

// Result:
// class InnerOuterPartialOuter1
//   Real a.x;
// end InnerOuterPartialOuter1;
// endResult
