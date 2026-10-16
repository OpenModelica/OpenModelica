// name: RedeclareConstrainingType2
// keywords:
// status: incorrect
//
// Checks that the type of a replaceable component is used as constraining type
// when there's no constrainedby clause.
//

model A
  Real x;
end A;

model B
  extends A;
  Real y;
end B;

model M
  replaceable B b;
end M;

model RedeclareConstrainingType2
  extends M;
  redeclare A b;
end RedeclareConstrainingType2;

// Result:
// Error processing file: RedeclareConstrainingType2.mo
// [flattening/modelica/scodeinst/RedeclareConstrainingType2.mo:24:3-24:16:writable] Notification: From here:
// [flattening/modelica/scodeinst/RedeclareConstrainingType2.mo:19:3-19:18:writable] Error: Redeclaration of component 'b' is not a subtype of the constraining type B, the element 'y' is missing or has an incompatible type.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
