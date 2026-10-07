// name:     Modification4
// keywords: modification
// status:   incorrect
//
// Error since no p inside A.

class A
  Integer x = 1;
end A;

class B
  A a;
end B;

class Modification4
  B b(a(p=2));
end Modification4;

// Result:
// Error processing file: Modification4.mo
// [flattening/modelica/modification/Modification4.mo:16:9-16:12:writable] Error: Modified element p not found in class A.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
