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
// [flattening/modelica/scodeinst/InnerOuterNotInner1.mo:8:3-8:15:writable] Notification: From here:
// [flattening/modelica/scodeinst/InnerOuterNotInner1.mo:12:3-12:9:writable] Warning: Ignoring non-inner x when looking for inner.
//
// endResult
