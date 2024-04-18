// name: InnerOuter12
// keywords:
// status: correct
// cflags: -d=newInst
//

model A
  outer B b;
  Real x;
end A;

model B
  A a;
end B;

model InnerOuter12
  inner B b;
end InnerOuter12;

// Result:
// class InnerOuter12
//   Real b.a.x;
// end InnerOuter12;
// endResult
