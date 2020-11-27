// name: InnerOuterMissing5
// keywords:
// status: correct
// cflags: -d=newInst
//

model A
  Real x = 1.0;
end A;

model B
  outer model M = A;
  M m;
end B;

model InnerOuterMissing5
  B b;
end InnerOuterMissing5;

// Result:
// class InnerOuterMissing5
//   Real b.m.x = 1.0;
// end InnerOuterMissing5;
// [flattening/modelica/scodeinst/InnerOuterMissing5.mo:12:9-12:20:writable] Warning: An inner declaration for outer class M could not be found and was automatically generated.
//
// endResult
