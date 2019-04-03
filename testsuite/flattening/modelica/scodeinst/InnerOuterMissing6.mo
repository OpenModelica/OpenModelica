// name: InnerOuterMissing6
// keywords:
// status: correct
// cflags: -d=newInst
//

model A
  outer Real x;
end A;

model InnerOuterMissing6 = A;

// Result:
// class InnerOuterMissing6
//   Real x;
// end InnerOuterMissing6;
// [flattening/modelica/scodeinst/InnerOuterMissing6.mo:8:3-8:15:writable] Warning: An inner declaration for outer component x could not be found and was automatically generated.
//
// endResult
