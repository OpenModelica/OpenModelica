// name: RedeclareEnum2
// keywords:
// status: incorrect
// cflags: -d=newInst
//

model A
  replaceable type E = enumeration(a);
  E e;
end A;

model RedeclareEnum2
  extends A(redeclare type E = enumeration(a, b, c));
end RedeclareEnum2;


// Result:
// Error processing file: RedeclareEnum2.mo
// [flattening/modelica/scodeinst/RedeclareEnum2.mo:13:23-13:52:writable] Notification: From here:
// [flattening/modelica/scodeinst/RedeclareEnum2.mo:8:15-8:38:writable] Error: Redeclaration of enumeration 'E' is not a subtype of the redeclared element (use enumeration(:) for a generic replaceable enumeration).
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
