// name: RedeclareConstrainingType3
// keywords:
// status: incorrect
//
// Checks that the types of nested components are compared when checking that
// a redeclared component is a subtype of the constraining type.
//

record R1
  Real x;
end R1;

record R2
  Integer x;
end R2;

model A
  R1 r;
end A;

model B
  R2 r;
end B;

model M
  replaceable A a;
end M;

model RedeclareConstrainingType3
  M m(redeclare B a);
end RedeclareConstrainingType3;

// Result:
// Error processing file: RedeclareConstrainingType3.mo
// [flattening/modelica/scodeinst/RedeclareConstrainingType3.mo:30:7-30:20:writable] Notification: From here:
// [flattening/modelica/scodeinst/RedeclareConstrainingType3.mo:26:3-26:18:writable] Error: Redeclaration of component 'a' is not a subtype of the constraining type A, the element 'r.x' is missing or has an incompatible type.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
