// name: RedeclareConstrainingType1
// keywords:
// status: incorrect
//
// Checks that a redeclared component must be a subtype of the constraining
// type given by a constrainedby clause, see #1080.
//

model A
  Real x;
end A;

model B
  extends A;
  Real y;
end B;

model C
  Real z;
end C;

model M
  replaceable B b constrainedby A;
end M;

model RedeclareConstrainingType1
  M m(redeclare C b);
end RedeclareConstrainingType1;

// Result:
// Error processing file: RedeclareConstrainingType1.mo
// [flattening/modelica/scodeinst/RedeclareConstrainingType1.mo:27:7-27:20:writable] Notification: From here:
// [flattening/modelica/scodeinst/RedeclareConstrainingType1.mo:23:3-23:34:writable] Error: Redeclaration of component 'b' is not a subtype of the constraining type A, the element 'x' is missing or has an incompatible type.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
