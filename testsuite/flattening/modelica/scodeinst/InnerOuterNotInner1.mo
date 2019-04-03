// name: InnerOuterNotInner1
// keywords: 
// status: correct
// cflags: -d=newInst
//

model A
  outer Real x;
end A;

model B
  Real x;
  A a;
end B;

model InnerOuterNotInner1
  inner Real x = 1.0;
  B b;
end InnerOuterNotInner1;

// Result:
// class InnerOuterNotInner1
//   Real x = 1.0;
//   Real b.x;
// end InnerOuterNotInner1;
// endResult
