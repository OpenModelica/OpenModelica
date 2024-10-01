// name: InnerOuterMissing8
// keywords:
// status: correct
//

model A
  model B
    Real x;
  end B;

  outer B b;
end A;

model InnerOuterMissing8
  A a;
end InnerOuterMissing8;

// Result:
// class InnerOuterMissing8
//   Real b.x;
// end InnerOuterMissing8;
// [flattening/modelica/scodeinst/InnerOuterMissing8.mo:11:3-11:12:writable] Warning: An inner declaration for outer component b could not be found and was automatically generated.
//
// endResult
