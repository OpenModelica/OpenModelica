// name: InnerOuterMissing4
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
  Real y = a.x;
end B;

model C
  outer A a;
  Real z = a.x;
end C;

model InnerOuterMissing4
  B b;
  C c;
end InnerOuterMissing4;

// Result:
// class InnerOuterMissing4
//   Real b.y = a.x;
//   Real c.z = a.x;
//   Real a.x;
// end InnerOuterMissing4;
// [flattening/modelica/scodeinst/InnerOuterMissing4.mo:18:3-18:12:writable] Warning: An inner declaration for outer component a could not be found and was automatically generated.
// [flattening/modelica/scodeinst/InnerOuterMissing4.mo:18:3-18:12:writable] Notification: The diagnostics message for the missing inner is: Missing outer A
//
// endResult
