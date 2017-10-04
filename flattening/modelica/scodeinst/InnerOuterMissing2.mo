// name: InnerOuterMissing2
// keywords:
// status: correct
// cflags: -d=newInst
//

model A
  Real x;
  annotation(missingInnerMessage = "Missing outer A");
end A;

model InnerOuterMissing2
  outer A a;
end InnerOuterMissing2;

// Result:
// class InnerOuterMissing2
//   Real a.x;
// end InnerOuterMissing2;
// [flattening/modelica/scodeinst/InnerOuterMissing2.mo:13:3-13:12:writable] Warning: An inner declaration for outer component a could not be found and was automatically generated.
// [flattening/modelica/scodeinst/InnerOuterMissing2.mo:13:3-13:12:writable] Notification: The diagnostics message for the missing inner is: Missing outer A
//
// endResult
