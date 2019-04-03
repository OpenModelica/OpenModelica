// name: InnerOuterMissing3
// keywords:
// status: correct
// cflags: -d=newInst
//

model A
  Real x;
  annotation(missingInnerMessage = "Missing outer A");
end A;

model B
  outer A a;
end B;

model InnerOuterMissing3
  B b1, b2;
end InnerOuterMissing3;

// Result:
// class InnerOuterMissing3
//   Real a.x;
// end InnerOuterMissing3;
// [flattening/modelica/scodeinst/InnerOuterMissing3.mo:13:3-13:12:writable] Warning: An inner declaration for outer component a could not be found and was automatically generated.
// [flattening/modelica/scodeinst/InnerOuterMissing3.mo:13:3-13:12:writable] Notification: The diagnostics message for the missing inner is: Missing outer A
//
// endResult
