// name: RedeclareEnum6
// keywords:
// status: incorrect
// cflags: -d=newInst
//

model A
  replaceable type E = enumeration(:);
  E e;
end A;

model RedeclareEnum6
  extends A(redeclare type E = E2);
  type E2 = Real;
end RedeclareEnum6;


// Result:
// Error processing file: RedeclareEnum6.mo
// [flattening/modelica/scodeinst/RedeclareEnum6.mo:13:23-13:34:writable] Notification: From here:
// [flattening/modelica/scodeinst/RedeclareEnum6.mo:8:15-8:38:writable] Error: Redeclaration of enumeration 'E' is not a subtype of the redeclared element.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
