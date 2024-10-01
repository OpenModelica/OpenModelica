// name: InnerOuterMissing6
// keywords:
// status: correct
//

model A
  outer Real x;
end A;

model B = A;

model InnerOuterMissing6
  B b;
end InnerOuterMissing6;

// Result:
// class InnerOuterMissing6
//   Real x;
// end InnerOuterMissing6;
// [flattening/modelica/scodeinst/InnerOuterMissing6.mo:7:3-7:15:writable] Warning: An inner declaration for outer component x could not be found and was automatically generated.
//
// endResult
