// name: InnerOuterMissing1
// keywords:
// status: correct
// cflags: -d=newInst
//

model InnerOuterMissing1
  outer Real x;
end InnerOuterMissing1;

// Result:
// class InnerOuterMissing1
//   Real x;
// end InnerOuterMissing1;
// [flattening/modelica/scodeinst/InnerOuterMissing1.mo:8:3-8:15:writable] Warning: An inner declaration for outer component x could not be found and was automatically generated.
//
// endResult
