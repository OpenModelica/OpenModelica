// name: RedeclareComponentType2
// keywords:
// status: incorrect
//
// Checks that a component of a non-basic type can't be redeclared with a
// basic type.
//

record R
  Real x;
end R;

model A
  replaceable R r;
end A;

model RedeclareComponentType2
  extends A;
  redeclare Real r;
end RedeclareComponentType2;

// Result:
// Error processing file: RedeclareComponentType2.mo
// [flattening/modelica/scodeinst/RedeclareComponentType2.mo:19:3-19:19:writable] Notification: From here:
// [flattening/modelica/scodeinst/RedeclareComponentType2.mo:14:3-14:18:writable] Error: Redeclaration of component 'r' is not a subtype of the redeclared element.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
