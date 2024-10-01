// name: InnerOuterMissing2
// keywords:
// status: correct
//

model A
  Real x;
  annotation(missingInnerMessage = "Missing outer A");
end A;

model B
  outer A a;
end B;

model InnerOuterMissing2
  B b;
end InnerOuterMissing2;

// Result:
// class InnerOuterMissing2
//   Real a.x;
// end InnerOuterMissing2;
// [flattening/modelica/scodeinst/InnerOuterMissing2.mo:12:3-12:12:writable] Warning: An inner declaration for outer component a could not be found and was automatically generated.
// [flattening/modelica/scodeinst/InnerOuterMissing2.mo:12:3-12:12:writable] Notification: The diagnostics message for the missing inner is: Missing outer A
//
// endResult
